codeunit 230 GenJnlManagement
{
    // APNT-LM1.0        02.08.12        Shameema        Added code for Lease Management
    // DP = changes made by DVS
    // APNT-HR1.0        13.11.13        Sangeeta        Added Payroll Option in FormTemplate Parameter of Function TemplateSelection
    //                                                   for HR & Payroll Customization.

    Permissions = TableData 80 = imd,
                  TableData 232 = imd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Fixed Asset G/L Journal';
        Text001: Label '%1 journal';
        Text002: Label 'RECURRING';
        Text003: Label 'Recurring General Journal';
        Text004: Label 'DEFAULT';
        Text005: Label 'Default Journal';
        LastGenJnlLine: Record "81";
        OpenFromBatch: Boolean;

    procedure TemplateSelection(FormID: Integer; FormTemplate: Option General,Sales,Purchases,"Cash Receipts",Payments,Assets,Intercompany,Jobs,Payroll; RecurringJnl: Boolean; var GenJnlLine: Record "81"; var JnlSelected: Boolean)
    var
        GenJnlTemplate: Record "80";
    begin
        JnlSelected := TRUE;

        GenJnlTemplate.RESET;
        GenJnlTemplate.SETRANGE("Form ID", FormID);
        GenJnlTemplate.SETRANGE(Recurring, RecurringJnl);
        IF NOT RecurringJnl THEN
            GenJnlTemplate.SETRANGE(Type, FormTemplate);
        //DP6.01.01 START
        GenJnlTemplate.SETRANGE("Receipt Journal", FALSE);
        GenJnlTemplate.SETRANGE("Post Receipt Journal", FALSE);
        //DP6.01.01 STOP

        CASE GenJnlTemplate.COUNT OF
            0:
                BEGIN
                    GenJnlTemplate.INIT;
                    GenJnlTemplate.Type := FormTemplate;
                    GenJnlTemplate.Recurring := RecurringJnl;
                    IF NOT RecurringJnl THEN BEGIN
                        GenJnlTemplate.Name := FORMAT(GenJnlTemplate.Type, MAXSTRLEN(GenJnlTemplate.Name));
                        IF FormTemplate = FormTemplate::Assets THEN
                            GenJnlTemplate.Description := Text000
                        ELSE
                            GenJnlTemplate.Description := STRSUBSTNO(Text001, GenJnlTemplate.Type);
                    END ELSE BEGIN
                        GenJnlTemplate.Name := Text002;
                        GenJnlTemplate.Description := Text003;
                    END;
                    GenJnlTemplate.VALIDATE(Type);
                    GenJnlTemplate.INSERT;
                    COMMIT;
                END;
            1:
                GenJnlTemplate.FIND('-');
            ELSE
                JnlSelected := FORM.RUNMODAL(0, GenJnlTemplate) = ACTION::LookupOK;
        END;
        IF JnlSelected THEN BEGIN
            GenJnlLine.FILTERGROUP := 2;
            GenJnlLine.SETRANGE("Journal Template Name", GenJnlTemplate.Name);
            GenJnlLine.FILTERGROUP := 0;
            IF OpenFromBatch THEN BEGIN
                GenJnlLine."Journal Template Name" := '';
                FORM.RUN(GenJnlTemplate."Form ID", GenJnlLine);
            END;
        END;
    end;

    procedure TemplateSelectionFromBatch(var GenJnlBatch: Record "232")
    var
        GenJnlLine: Record "81";
        JnlSelected: Boolean;
        GenJnlTemplate: Record "80";
    begin
        OpenFromBatch := TRUE;
        GenJnlTemplate.GET(GenJnlBatch."Journal Template Name");
        GenJnlTemplate.TESTFIELD("Form ID");
        GenJnlBatch.TESTFIELD(Name);

        GenJnlLine.FILTERGROUP := 2;
        GenJnlLine.SETRANGE("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLine.FILTERGROUP := 0;

        GenJnlLine."Journal Template Name" := '';
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        FORM.RUN(GenJnlTemplate."Form ID", GenJnlLine);
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "81")
    begin
        CheckTemplateName(GenJnlLine.GETRANGEMAX("Journal Template Name"), CurrentJnlBatchName);
        GenJnlLine.FILTERGROUP := 2;
        GenJnlLine.SETRANGE("Journal Batch Name", CurrentJnlBatchName);
        GenJnlLine.FILTERGROUP := 0;
    end;

    procedure OpenJnlBatch(var GenJnlBatch: Record "232")
    var
        GenJnlTemplate: Record "80";
        GenJnlLine: Record "81";
        GenJnlBatch2: Record "232";
        JnlSelected: Boolean;
    begin
        IF GenJnlBatch.GETFILTER("Journal Template Name") <> '' THEN
            EXIT;
        GenJnlBatch.FILTERGROUP(2);
        IF GenJnlBatch.GETFILTER("Journal Template Name") <> '' THEN BEGIN
            GenJnlBatch.FILTERGROUP(0);
            EXIT;
        END;
        GenJnlBatch.FILTERGROUP(0);

        IF NOT GenJnlBatch.FIND('-') THEN BEGIN
            FOR GenJnlTemplate.Type := GenJnlTemplate.Type::General TO GenJnlTemplate.Type::Jobs DO BEGIN
                GenJnlTemplate.SETRANGE(Type, GenJnlTemplate.Type);
                IF NOT GenJnlTemplate.FIND('-') THEN
                    TemplateSelection(0, GenJnlTemplate.Type, FALSE, GenJnlLine, JnlSelected);
                IF GenJnlTemplate.FIND('-') THEN
                    CheckTemplateName(GenJnlTemplate.Name, GenJnlBatch.Name);
                IF GenJnlTemplate.Type = GenJnlTemplate.Type::General THEN BEGIN
                    GenJnlTemplate.SETRANGE(Recurring, TRUE);
                    IF NOT GenJnlTemplate.FIND('-') THEN
                        TemplateSelection(0, GenJnlTemplate.Type, TRUE, GenJnlLine, JnlSelected);
                    IF GenJnlTemplate.FIND('-') THEN
                        CheckTemplateName(GenJnlTemplate.Name, GenJnlBatch.Name);
                    GenJnlTemplate.SETRANGE(Recurring);
                END;
            END;
        END;
        GenJnlBatch.FIND('-');
        JnlSelected := TRUE;
        GenJnlBatch.CALCFIELDS("Template Type", Recurring);
        GenJnlTemplate.SETRANGE(Recurring, GenJnlBatch.Recurring);
        IF NOT GenJnlBatch.Recurring THEN
            GenJnlTemplate.SETRANGE(Type, GenJnlBatch."Template Type");
        IF GenJnlBatch.GETFILTER("Journal Template Name") <> '' THEN
            GenJnlTemplate.SETRANGE(Name, GenJnlBatch.GETFILTER("Journal Template Name"));
        CASE GenJnlTemplate.COUNT OF
            1:
                GenJnlTemplate.FIND('-');
            ELSE
                JnlSelected := FORM.RUNMODAL(0, GenJnlTemplate) = ACTION::LookupOK;
        END;
        IF NOT JnlSelected THEN
            ERROR('');

        GenJnlBatch.FILTERGROUP(0);
        GenJnlBatch.SETRANGE("Journal Template Name", GenJnlTemplate.Name);
        GenJnlBatch.FILTERGROUP(2);
    end;

    procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        GenJnlBatch: Record "232";
    begin
        GenJnlBatch.SETRANGE("Journal Template Name", CurrentJnlTemplateName);
        IF NOT GenJnlBatch.GET(CurrentJnlTemplateName, CurrentJnlBatchName) THEN BEGIN
            IF NOT GenJnlBatch.FIND('-') THEN BEGIN
                GenJnlBatch.INIT;
                GenJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
                GenJnlBatch.SetupNewBatch;
                GenJnlBatch.Name := Text004;
                GenJnlBatch.Description := Text005;
                GenJnlBatch.INSERT(TRUE);
                COMMIT;
            END;
            CurrentJnlBatchName := GenJnlBatch.Name
        END;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "81")
    var
        GenJnlBatch: Record "232";
    begin
        GenJnlBatch.GET(GenJnlLine.GETRANGEMAX("Journal Template Name"), CurrentJnlBatchName);
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "81")
    begin
        GenJnlLine.FILTERGROUP := 2;
        GenJnlLine.SETRANGE("Journal Batch Name", CurrentJnlBatchName);
        GenJnlLine.FILTERGROUP := 0;
        IF GenJnlLine.FIND('-') THEN;
    end;

    procedure LookupName(var CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "81")
    var
        GenJnlBatch: Record "232";
        LMSetup: Record "50502";
    begin
        COMMIT;
        GenJnlBatch."Journal Template Name" := GenJnlLine.GETRANGEMAX("Journal Template Name");
        GenJnlBatch.Name := GenJnlLine.GETRANGEMAX("Journal Batch Name");
        GenJnlBatch.FILTERGROUP(2);
        GenJnlBatch.SETRANGE("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlBatch.FILTERGROUP(0);
        //APNT-LM1.0.1 -
        LMSetup.GET;
        IF (LMSetup.Template <> '') AND (LMSetup.Batch <> '') THEN BEGIN
            IF GenJnlBatch."Journal Template Name" = LMSetup.Template THEN
                GenJnlBatch.SETFILTER(GenJnlBatch.Name, '<>%1', LMSetup.Batch);
        END;
        //APNT-LM1.0.1 +
        IF FORM.RUNMODAL(0, GenJnlBatch) = ACTION::LookupOK THEN BEGIN
            CurrentJnlBatchName := GenJnlBatch.Name;
            SetName(CurrentJnlBatchName, GenJnlLine);
        END;
    end;

    procedure GetAccounts(var GenJnlLine: Record "81"; var AccName: Text[50]; var BalAccName: Text[50])
    var
        GLAcc: Record "15";
        Cust: Record "18";
        Vend: Record "23";
        BankAcc: Record "270";
        FA: Record "5600";
        IC: Record "413";
    begin
        IF (GenJnlLine."Account Type" <> LastGenJnlLine."Account Type") OR
           (GenJnlLine."Account No." <> LastGenJnlLine."Account No.")
        THEN BEGIN
            AccName := '';
            IF GenJnlLine."Account No." <> '' THEN
                CASE GenJnlLine."Account Type" OF
                    GenJnlLine."Account Type"::"G/L Account":
                        IF GLAcc.GET(GenJnlLine."Account No.") THEN
                            AccName := GLAcc.Name;
                    GenJnlLine."Account Type"::Customer:
                        IF Cust.GET(GenJnlLine."Account No.") THEN
                            AccName := Cust.Name;
                    GenJnlLine."Account Type"::Vendor:
                        IF Vend.GET(GenJnlLine."Account No.") THEN
                            AccName := Vend.Name;
                    GenJnlLine."Account Type"::"Bank Account":
                        IF BankAcc.GET(GenJnlLine."Account No.") THEN
                            AccName := BankAcc.Name;
                    GenJnlLine."Account Type"::"Fixed Asset":
                        IF FA.GET(GenJnlLine."Account No.") THEN
                            AccName := FA.Description;
                    GenJnlLine."Account Type"::"IC Partner":
                        IF IC.GET(GenJnlLine."Account No.") THEN
                            AccName := IC.Name;

                END;
        END;

        IF (GenJnlLine."Bal. Account Type" <> LastGenJnlLine."Bal. Account Type") OR
           (GenJnlLine."Bal. Account No." <> LastGenJnlLine."Bal. Account No.") THEN BEGIN
            BalAccName := '';
            IF GenJnlLine."Bal. Account No." <> '' THEN
                CASE GenJnlLine."Bal. Account Type" OF
                    GenJnlLine."Bal. Account Type"::"G/L Account":
                        IF GLAcc.GET(GenJnlLine."Bal. Account No.") THEN
                            BalAccName := GLAcc.Name;
                    GenJnlLine."Bal. Account Type"::Customer:
                        IF Cust.GET(GenJnlLine."Bal. Account No.") THEN
                            BalAccName := Cust.Name;
                    GenJnlLine."Bal. Account Type"::Vendor:
                        IF Vend.GET(GenJnlLine."Bal. Account No.") THEN
                            BalAccName := Vend.Name;
                    GenJnlLine."Bal. Account Type"::"Bank Account":
                        IF BankAcc.GET(GenJnlLine."Bal. Account No.") THEN
                            BalAccName := BankAcc.Name;
                    GenJnlLine."Bal. Account Type"::"Fixed Asset":
                        IF FA.GET(GenJnlLine."Bal. Account No.") THEN
                            BalAccName := FA.Description;
                    GenJnlLine."Bal. Account Type"::"IC Partner":
                        IF IC.GET(GenJnlLine."Bal. Account No.") THEN
                            BalAccName := IC.Name;

                END;
        END;

        LastGenJnlLine := GenJnlLine;
    end;

    procedure CalcBalance(var GenJnlLine: Record "81"; LastGenJnlLine: Record "81"; var Balance: Decimal; var TotalBalance: Decimal; var ShowBalance: Boolean; var ShowTotalBalance: Boolean)
    var
        TempGenJnlLine: Record "81";
    begin
        TempGenJnlLine.COPYFILTERS(GenJnlLine);
        ShowTotalBalance := TempGenJnlLine.CALCSUMS("Balance (LCY)");
        IF ShowTotalBalance THEN BEGIN
            TotalBalance := TempGenJnlLine."Balance (LCY)";
            IF GenJnlLine."Line No." = 0 THEN
                TotalBalance := TotalBalance + LastGenJnlLine."Balance (LCY)";
        END;

        IF GenJnlLine."Line No." <> 0 THEN BEGIN
            TempGenJnlLine.SETRANGE("Line No.", 0, GenJnlLine."Line No.");
            ShowBalance := TempGenJnlLine.CALCSUMS("Balance (LCY)");
            IF ShowBalance THEN
                Balance := TempGenJnlLine."Balance (LCY)";
        END ELSE BEGIN
            TempGenJnlLine.SETRANGE("Line No.", 0, LastGenJnlLine."Line No.");
            ShowBalance := TempGenJnlLine.CALCSUMS("Balance (LCY)");
            IF ShowBalance THEN BEGIN
                Balance := TempGenJnlLine."Balance (LCY)";
                TempGenJnlLine.COPYFILTERS(GenJnlLine);
                TempGenJnlLine := LastGenJnlLine;
                IF TempGenJnlLine.NEXT = 0 THEN
                    Balance := Balance + LastGenJnlLine."Balance (LCY)";
            END;
        END;
    end;
}

