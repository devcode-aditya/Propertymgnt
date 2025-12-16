codeunit 33016805 "Sales Import"
{

    trigger OnRun()
    begin
        IntegrationSetup.GET;
        IntegrationSetup.TESTFIELD("FTP Host (Import)");
        IntegrationSetup.TESTFIELD("FTP Login (Import)");
        IntegrationSetup.TESTFIELD("FTP Password (Import)");

        ImportSales;
    end;

    var
        IntegrationSetup: Record "SMS Integration Setup";
        FTPScript: File;
        WshShell: Automation BC;
        WaitOnReturn: Boolean;
        WindowType: Option;
        FileName: Text[100];
        FileRec: Record "2000000022";
        Text001: Label 'Client Store Mapping does not exist for Store %1';
        Text002: Label 'Setup does not exist for Client Product Group %1';
        Text003: Label 'Currency Code %1 does not exist';

    procedure ImportSales()
    var
        FileRec: Record "2000000022";
        SalesDpt: Dataport "33016800";
        IntegrationRegister: Record "Integration Register";
        NextLineNo: Integer;
        IntegrationRegisterRec: Record "Integration Register";
    begin
        IntegrationSetup.TESTFIELD("FTP Location (Sales Trans.)");
        IntegrationSetup.TESTFIELD("Local Location (Sales Trans.)");
        IntegrationSetup.TESTFIELD("Archive Location (Sales Trans)");
        IntegrationSetup.TESTFIELD("Duplicate Loc. (Sales Trans.)");
        IntegrationSetup.TESTFIELD("File Suffix (Sales Trans.)");

        CLEAR(FileName);
        FileName := ENVIRON('TEMP') + '\' + IntegrationSetup."File Suffix (Sales Trans.)" + '.bat';
        IF EXISTS(FileName) THEN
            FILE.ERASE(FileName);

        CLEAR(FTPScript);
        FTPScript.CREATE(FileName);
        FTPScript.WRITEMODE(TRUE);
        FTPScript.TEXTMODE(TRUE);
        FTPScript.WRITE('@ECHO OFF');
        FTPScript.WRITE('CD ' + ENVIRON('TEMP'));
        FTPScript.WRITE('> script.ftp ECHO open ' + IntegrationSetup."FTP Host (Import)");
        FTPScript.WRITE('>>script.ftp ECHO USER ' + IntegrationSetup."FTP Login (Import)");
        FTPScript.WRITE('>>script.ftp ECHO ' + IntegrationSetup."FTP Password (Import)");
        FTPScript.WRITE('>>script.ftp ECHO CD ' + IntegrationSetup."FTP Location (Sales Trans.)");
        FTPScript.WRITE('>>script.ftp ECHO prompt');
        FTPScript.WRITE('>>script.ftp ECHO bin');
        FTPScript.WRITE('>>script.ftp ECHO lcd ' + IntegrationSetup."Local Location (Sales Trans.)");
        FTPScript.WRITE('>>script.ftp ECHO mget *' + IntegrationSetup."File Suffix (Sales Trans.)" + '*.csv');
        FTPScript.WRITE('>>script.ftp ECHO mdelete *' + IntegrationSetup."File Suffix (Sales Trans.)" + '*.csv');
        FTPScript.WRITE('>>script.ftp ECHO CD ' + IntegrationSetup."FTP Archive (Sales Trans.)");
        FTPScript.WRITE('>>script.ftp ECHO mput *' + IntegrationSetup."File Suffix (Sales Trans.)" + '*.csv');
        FTPScript.WRITE('>>script.ftp ECHO Bye');
        FTPScript.WRITE('FTP -s:script.ftp -n ' + IntegrationSetup."FTP Host (Import)");
        FTPScript.WRITE('TYPE NUL >script.ftp');
        FTPScript.WRITE('DEL script.ftp');
        FTPScript.WRITE(':retry_del');
        FTPScript.WRITE('DEL "' + FileName + '" > NUL');
        FTPScript.WRITE('if exist "' + FileName + '" goto retry_del');
        FTPScript.CLOSE;

        IF ISCLEAR(WshShell) THEN
            CREATE(WshShell);
        WaitOnReturn := TRUE;
        WshShell.Run(FileName, WindowType, WaitOnReturn);
        CLEAR(WshShell);

        FileRec.RESET;
        FileRec.SETRANGE(Path, IntegrationSetup."Local Location (Sales Trans.)");
        FileRec.SETRANGE("Is a file", TRUE);
        IF FileRec.FINDSET THEN BEGIN
            IntegrationRegister.RESET;
            IF IntegrationRegister.FINDLAST THEN
                NextLineNo := IntegrationRegister."S.No";
            NextLineNo := NextLineNo + 1;
            IntegrationRegister.RESET;
            REPEAT
                IntegrationRegisterRec.RESET;
                IntegrationRegisterRec.SETRANGE("File Name", IntegrationSetup."Local Location (Sales Trans.)" + '\' + FileRec.Name);
                IF NOT IntegrationRegisterRec.FINDFIRST THEN BEGIN

                    IntegrationRegister.INIT;
                    IntegrationRegister."S.No" := NextLineNo;
                    IntegrationRegister."File Name" := IntegrationSetup."Local Location (Sales Trans.)" + '\' + FileRec.Name;

                    CLEAR(SalesDpt);
                    SalesDpt.SetDPAttributes(IntegrationRegister."S.No");
                    SalesDpt.IMPORT := TRUE;
                    SalesDpt.FILENAME := IntegrationSetup."Local Location (Sales Trans.)" + '\' + FileRec.Name;
                    SalesDpt.RUNMODAL;

                    IntegrationRegister.Status := IntegrationRegister.Status::"Imported to Staging Table";
                    IntegrationRegister.Date := TODAY;
                    IntegrationRegister.Time := TIME;
                    IntegrationRegister."File Type" := IntegrationRegister."File Type"::Sales;
                    IntegrationRegister.Type := IntegrationRegister.Type::Import;
                    IntegrationRegister.INSERT;
                    NextLineNo := NextLineNo + 1;
                    MoveTheFile(IntegrationSetup."Local Location (Sales Trans.)", IntegrationSetup."Archive Location (Sales Trans)", FileRec.Name)
              ;
                END ELSE
                    MoveTheFile(IntegrationSetup."Local Location (Sales Trans.)", IntegrationSetup."Duplicate Loc. (Sales Trans.)", FileRec.Name);
            UNTIL FileRec.NEXT = 0;
        END;

        COMMIT;
        CreateClientSalesEntries;
    end;

    procedure MoveTheFile(FromFile: Text[1024]; ToFile: Text[1024]; FileName1: Text[1024])
    var
        FSO: Automation BC;
        RecFile: Record "2000000022";
    begin
        IF COPY(FromFile + '\' + FileName1, ToFile + '\' + FileName1) THEN
            ERASE(FromFile + '\' + FileName1);
    end;

    procedure CreateClientSalesEntries()
    var
        IntegrationRegisterRec: Record "Integration Register";
        ClientStaging: Record "Client Sales Staging";
        ClientSalesRec: Record "Client Sales Transactions";
        SalesRec: Record "Client Sales Transactions";
        Noofrecords: Integer;
        RecInserted: Integer;
    begin
        //Creating records from Staging Table
        IntegrationRegisterRec.RESET;
        IntegrationRegisterRec.SETRANGE("File Type", IntegrationRegisterRec."File Type"::Sales);
        IntegrationRegisterRec.SETFILTER(Status, '<>%1', IntegrationRegisterRec.Status::"Imported to Master");
        IF IntegrationRegisterRec.FINDSET THEN
            REPEAT
                CLEAR(Noofrecords);
                CLEAR(RecInserted);
                ClientStaging.RESET;
                ClientStaging.SETFILTER(Status, '<>%1', ClientStaging.Status::"Imported to Master");
                ClientStaging.SETRANGE("Entry No. in Register", IntegrationRegisterRec."S.No");
                Noofrecords := ClientStaging.COUNT;
                IF ClientStaging.FINDSET THEN
                    REPEAT
                        IF ValidateData(ClientStaging) THEN BEGIN
                            IF NOT ClientSalesRec.GET(ClientStaging."Store No.", ClientStaging."Pos Terminal No.", ClientStaging."Transaction No.",
                              ClientStaging."Line No.") THEN BEGIN
                                SalesRec.INIT;
                                SalesRec.VALIDATE("Store No.", ClientStaging."Store No.");
                                SalesRec.VALIDATE("Pos Terminal No.", ClientStaging."Pos Terminal No.");
                                SalesRec.VALIDATE("Transaction No.", ClientStaging."Transaction No.");
                                SalesRec.VALIDATE("Line No.", ClientStaging."Line No.");
                                SalesRec.VALIDATE(Date, ClientStaging.Date);
                                SalesRec.VALIDATE(Time, ClientStaging.Time);
                                SalesRec.VALIDATE(Quantity, ClientStaging.Quantity);
                                SalesRec.VALIDATE("Net Amount", ClientStaging."Net Amount");
                                SalesRec.VALIDATE("Currency Code", ClientStaging."Currency Code");
                                SalesRec.VALIDATE("Currency Factor", ClientStaging."Currency Factor");
                                SalesRec.VALIDATE("Net Amount (LCY)", ClientStaging."Net Amount (LCY)");
                                SalesRec.VALIDATE("Client Product Group", ClientStaging."Client Product Group");
                                SalesRec.INSERT(TRUE);
                                RecInserted := RecInserted + 1;
                            END ELSE BEGIN
                                ClientSalesRec.INIT;
                                ClientSalesRec.VALIDATE(Date, ClientStaging.Date);
                                ClientSalesRec.VALIDATE(Time, ClientStaging.Time);
                                ClientSalesRec.VALIDATE(Quantity, ClientSalesRec.Quantity + ClientStaging.Quantity);
                                ClientSalesRec.VALIDATE("Net Amount", (ClientSalesRec."Net Amount" + ClientStaging."Net Amount"));
                                ClientSalesRec.VALIDATE("Net Amount (LCY)", (ClientSalesRec."Net Amount (LCY)" + ClientStaging."Net Amount (LCY)"));
                                ClientSalesRec.VALIDATE("Client Product Group", ClientStaging."Client Product Group");
                                ClientSalesRec.MODIFY(TRUE);
                                RecInserted := RecInserted + 1;
                            END;
                            ClientStaging.Status := ClientStaging.Status::"Imported to Master";
                            ClientStaging.MODIFY;
                        END ELSE BEGIN
                            ClientStaging.Status := ClientStaging.Status::Error;
                            ClientStaging.MODIFY;
                        END;
                    UNTIL ClientStaging.NEXT = 0;
                IF Noofrecords = RecInserted THEN BEGIN
                    IntegrationRegisterRec.Status := IntegrationRegisterRec.Status::"Imported to Master";
                    IntegrationRegisterRec.MODIFY;
                END ELSE BEGIN
                    IF RecInserted <> 0 THEN BEGIN
                        IntegrationRegisterRec.Status := IntegrationRegisterRec.Status::"Partially Imported to Master";
                        IntegrationRegisterRec.MODIFY;
                    END ELSE
                        IF RecInserted = 0 THEN BEGIN
                            IntegrationRegisterRec.Status := IntegrationRegisterRec.Status::" ";
                            IntegrationRegisterRec.MODIFY;
                        END;
                END;
            UNTIL IntegrationRegisterRec.NEXT = 0;
    end;

    procedure ValidateData(var ClientSalesStagingRec: Record "Client Sales Staging"): Boolean
    var
        ClientProductGroupRec: Record "Client Product Group";
        ClientStoreRec: Record "Client Store Mapping";
        CurrencyRec: Record Currency;
    begin
        ClientStoreRec.RESET;
        ClientStoreRec.SETRANGE("Client Store No.", ClientSalesStagingRec."Store No.");
        IF NOT ClientStoreRec.FINDFIRST THEN BEGIN
            ClientSalesStagingRec.Status := ClientSalesStagingRec.Status::Error;
            ClientSalesStagingRec."Error String" := STRSUBSTNO(Text001, ClientSalesStagingRec."Store No.");
            UpdateErrorRegister(ClientSalesStagingRec."Entry No. in Register", ClientSalesStagingRec."Entry No.",
            ClientSalesStagingRec."Error String");
            EXIT(FALSE);
        END;

        ClientProductGroupRec.RESET;
        ClientProductGroupRec.SETRANGE("Client Product Group", ClientSalesStagingRec."Client Product Group");
        IF NOT ClientProductGroupRec.FINDFIRST THEN BEGIN
            ClientSalesStagingRec.Status := ClientSalesStagingRec.Status::Error;
            ClientSalesStagingRec."Error String" := STRSUBSTNO(Text002, ClientSalesStagingRec."Client Product Group");
            UpdateErrorRegister(ClientSalesStagingRec."Entry No. in Register", ClientSalesStagingRec."Entry No.",
            ClientSalesStagingRec."Error String");
            EXIT(FALSE);
        END;

        EXIT(TRUE);
    end;

    procedure UpdateErrorRegister(RegisterEntryNo: Integer; StagingEntryNo: Integer; ErrorString: Text[100])
    var
        ErrorRegsiterRec: Record "Error Register";
        NextEntryNo: Integer;
    begin
        CLEAR(NextEntryNo);
        ErrorRegsiterRec.RESET;
        IF ErrorRegsiterRec.FINDLAST THEN
            NextEntryNo := ErrorRegsiterRec."Entry Number";
        NextEntryNo := NextEntryNo + 1;

        ErrorRegsiterRec.INIT;
        ErrorRegsiterRec."Entry Number" := NextEntryNo;
        ErrorRegsiterRec."Entry Number in Register" := RegisterEntryNo;
        ErrorRegsiterRec."Entry Number in Staging" := StagingEntryNo;
        ErrorRegsiterRec."Error String" := ErrorString;
        ErrorRegsiterRec.INSERT;
    end;
}

