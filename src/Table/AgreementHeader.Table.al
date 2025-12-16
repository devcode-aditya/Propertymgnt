table 33016815 "Agreement Header"
{
    // DP6.01.02 HK 19SEP2013 : Added Field "Pre-Close" and code for Pre-Closure functionality
    //                          Code modified to update header dimension
    // DP6.01.03 HK 06NOV2013 : Code modified to check Agreement linked with Premise
    // 230818  LALS           : To close VAT calculated agreements having negative balance.

    Caption = 'Agreement Header';
    // DrillDownFormID = Form33016849;
    // LookupFormID = Form33016849;

    fields
    {
        field(1; "No."; Code[20])
        {

            trigger OnValidate()
            begin
                IF "No." <> xRec."No." THEN BEGIN
                    PremiseMgt.GET;
                    NoSeriesMgt.TestManual(PremiseMgt.Agreement);
                    "No. Series" := '';
                END;
            end;
        }
        field(2; "Agreement Type"; Option)
        {
            OptionCaption = 'Lease,Sale';
            OptionMembers = Lease,Sale;
        }
        field(3; "Client No."; Code[20])
        {
            TableRelation = Customer WHERE(Client Type=FILTER(Client|Tenant));

            trigger OnValidate()
            var
                CustomerRec: Record Customer;
                AgreementLineRec: Record "Agreement Line";
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);

                IF "Client No." <> '' THEN BEGIN
                  CustomerRec.GET("Client No.");
                  "Client Name" := CustomerRec.Name;
                  "Client Address" := CustomerRec.Address;
                  "Client Address2" := CustomerRec."Address 2";
                  "Post Code" := CustomerRec."Post Code";
                  City := CustomerRec.City;
                  Country := CustomerRec."Country/Region Code";
                  "E-Mail" := CustomerRec."E-Mail";
                  "Phone No." := CustomerRec."Phone No.";
                  "Salesperson Code" := CustomerRec."Salesperson Code";
                  VALIDATE("Payment Terms Code",CustomerRec."Payment Terms Code");
                  //DP6.01.02 START
                  //"Global Dimension 1 Code" := CustomerRec."Global Dimension 1 Code";
                  //"Global Dimension 2 Code" := CustomerRec."Global Dimension 2 Code";
                  VALIDATE("Global Dimension 1 Code",CustomerRec."Global Dimension 1 Code");
                  VALIDATE("Global Dimension 2 Code",CustomerRec."Global Dimension 2 Code");
                  //DP6.01.02 START
                  "Currency Code" := CustomerRec."Currency Code";
                  "Client Segment" := CustomerRec."Client Segment";
                END ELSE BEGIN
                  "Client Name" := '';
                  "Client Address" := '';
                  "Client Address2" := '';
                  "Post Code" := '';
                  City := '';
                  Country := '';
                  "E-Mail" := '';
                  "Phone No." := '';
                  "Salesperson Code" := '';
                  VALIDATE("Payment Terms Code",'');
                  //DP6.01.02 START
                  //"Global Dimension 1 Code" := '';
                  //"Global Dimension 2 Code" := '';
                  VALIDATE("Global Dimension 1 Code",'');
                  VALIDATE("Global Dimension 2 Code",'');
                  //DP6.01.02 STOP
                  "Currency Code" := '';
                  "Client Segment" := '';
                END;

                UpdateClientDetails;
            end;
        }
        field(4;"Agreement Status";Option)
        {
            OptionCaption = 'New,Active,Cancelled,Closed';
            OptionMembers = New,Active,Cancelled,Closed;
        }
        field(5;"Approval Status";Option)
        {
            Editable = false;
            OptionCaption = 'Open,Released,Pending Approval';
            OptionMembers = Open,Released,"Pending Approval";
        }
        field(6;"Client Name";Text[50])
        {

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(7;"Client Address";Text[50])
        {

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(8;"Client Address2";Text[50])
        {

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(9;"Post Code";Code[20])
        {
            TableRelation = "Post Code".Code;

            trigger OnLookup()
            begin
                PostCode.LookUpCity(City,"Post Code",TRUE);
            end;

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
                PostCode.ValidateCity(City,"Post Code");
            end;
        }
        field(10;City;Text[30])
        {
            TableRelation = "Post Code".City WHERE (Code=FIELD(Post Code));

            trigger OnLookup()
            begin
                PostCode.LookUpCity(City,"Post Code",TRUE);
            end;

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
                PostCode.ValidateCity(City,"Post Code");
            end;
        }
        field(11;Country;Code[10])
        {
            TableRelation = Country/Region;

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(12;"E-Mail";Text[80])
        {

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);

                IF "E-Mail" <> '' THEN BEGIN
                  IF NOT (STRPOS("E-Mail",'@') <> 0) THEN
                    ERROR(STRSUBSTNO(Text001,"E-Mail"));
                  IF NOT (STRPOS("E-Mail",'.') <> 0) THEN
                    ERROR(STRSUBSTNO(Text001,"E-Mail"));
                END;
            end;
        }
        field(13;"Phone No.";Text[30])
        {

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(14;"Salesperson Code";Code[10])
        {
            TableRelation = Salesperson/Purchaser;

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(15;"Signature Date";Date)
        {

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(16;"Agreement Start Date";Date)
        {

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
                IF "Agreement Start Date" = 0D THEN
                  "Agreement End Date" := 0D
                ELSE BEGIN
                  TESTFIELD("Agreement Period");
                  "Agreement End Date" := CALCDATE("Agreement Period","Agreement Start Date");
                  "Agreement End Date" := CALCDATE('-1D',"Agreement End Date");
                END;
                UpdateAgreementLineDate;
            end;
        }
        field(17;"Agreement End Date";Date)
        {

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
                UpdateAgreementLineDate;
            end;
        }
        field(18;"Agreement Period";DateFormula)
        {

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(19;"Payment Terms Code";Code[10])
        {
            TableRelation = "Payment Terms";

            trigger OnValidate()
            var
                PaymentTerm: Record "Payment Terms";
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
                IF "Payment Terms Code" <> '' THEN BEGIN
                  PaymentTerm.GET("Payment Terms Code");
                  PaymentTerm.CALCFIELDS(PaymentTerm."Multiple Pay. Terms");
                  "Multiple Payment Terms" := PaymentTerm."Multiple Pay. Terms";
                END ELSE
                  "Multiple Payment Terms" := FALSE;
            end;
        }
        field(20;"Multiple Payment Terms";Boolean)
        {
            Editable = false;

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(21;"Calculated Area";Decimal)
        {
            BlankZero = true;
            Editable = false;

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(22;"Global Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,2,1';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
                ValidateShortcutDimCode(1,"Global Dimension 1 Code");
            end;
        }
        field(23;"Global Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,2,2';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
                ValidateShortcutDimCode(2,"Global Dimension 2 Code");
            end;
        }
        field(24;"Notice Date";Date)
        {

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(25;"Notice Expiry Date";Date)
        {

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(26;"No. of Premises";Integer)
        {
            BlankZero = true;
            CalcFormula = Count("Agreement Premise Relation" WHERE (Agreement No.=FIELD(No.),
                                                                    Agreement Type=FIELD(Agreement Type),
                                                                    Premise No.=FILTER(<>'')));
            Editable = false;
            FieldClass = FlowField;

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(27;"Sales Representative";Code[20])
        {
            TableRelation = "Sales Representative".No. WHERE (Blocked=CONST(No));

            trigger OnLookup()
            var
                AgreementPremiseRec: Record "Agreement Premise Relation";
                PremiseCommAgent: Record "Premise Sales Representative";
                AgentRec: Record "Sales Representative";
                AgentFrm: Form "33016800";
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
                AgreementPremiseRec.RESET;
                AgreementPremiseRec.SETRANGE("Agreement Type","Agreement Type");
                AgreementPremiseRec.SETRANGE("Agreement No.","No.");
                AgreementPremiseRec.SETFILTER("Premise No.",'<>%1','');
                IF AgreementPremiseRec.FINDSET THEN BEGIN
                  AgentRec.CLEARMARKS;
                  REPEAT
                    PremiseCommAgent.RESET;
                    PremiseCommAgent.SETRANGE("Premise No.",AgreementPremiseRec."Premise No.");
                    IF PremiseCommAgent.FINDSET THEN
                      REPEAT
                        IF AgentRec.GET(PremiseCommAgent."Sales Representative") THEN
                           AgentRec.MARK(TRUE);
                      UNTIL PremiseCommAgent.NEXT = 0;
                  UNTIL AgreementPremiseRec.NEXT = 0;
                END;

                AgentRec.MARKEDONLY(TRUE);
                CLEAR(AgentFrm);
                AgentFrm.SETTABLEVIEW(AgentRec);
                AgentFrm.LOOKUPMODE(TRUE);
                IF AgentFrm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                  AgentFrm.GETRECORD(AgentRec);
                  "Sales Representative" := AgentRec."No.";
                END;
            end;

            trigger OnValidate()
            var
                AgreementPremiseRec: Record "Agreement Premise Relation";
                PremiseCommAgent: Record "Premise Sales Representative";
                Chk: Boolean;
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);

                IF "Sales Representative" <> '' THEN BEGIN
                  AgreementPremiseRec.RESET;
                  AgreementPremiseRec.SETRANGE("Agreement Type","Agreement Type");
                  AgreementPremiseRec.SETRANGE("Agreement No.","No.");
                  AgreementPremiseRec.SETFILTER("Premise No.",'<>%1','');
                  IF AgreementPremiseRec.FINDSET THEN BEGIN
                    REPEAT
                      PremiseCommAgent.RESET;
                      PremiseCommAgent.SETRANGE("Premise No.",AgreementPremiseRec."Premise No.");
                      PremiseCommAgent.SETRANGE("Sales Representative","Sales Representative");
                      IF PremiseCommAgent.FINDFIRST THEN
                         Chk := TRUE;
                    UNTIL (AgreementPremiseRec.NEXT = 0) OR Chk;
                    IF NOT Chk THEN
                      "Sales Representative" := '';
                  END ELSE
                    "Sales Representative" := '';
                END;
            end;
        }
        field(28;"No. Series";Code[10])
        {
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(29;"Currency Code";Code[10])
        {
            TableRelation = Currency;

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
                IF "Currency Code" <> '' THEN BEGIN
                 UpdateCurrencyFactor;
                IF "Currency Factor" <> xRec."Currency Factor" THEN
                 ConfirmUpdateCurrencyFactor;
                 END;
                //UpdateCurrencyFactor
                RecreateAgreementLines;
            end;
        }
        field(30;Comment;Boolean)
        {
            CalcFormula = Exist("Premise Comment" WHERE (Table Name=CONST(Agreement),
                                                         No.=FIELD(No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(31;"Invoice Frequency";Code[10])
        {
            TableRelation = "Error Register";
        }
        field(32;"Client Segment";Code[20])
        {
            Editable = false;
            TableRelation = "Client Segment";
        }
        field(33;"Total Original Amount";Decimal)
        {
            CalcFormula = Sum("Agreement Line"."Original Amount" WHERE (Agreement No.=FIELD(No.),
                                                                        Agreement Type=FIELD(Agreement Type),
                                                                        Sales Representative=FIELD(Sales Representative),
                                                                        Signature Date=FIELD(Signature Date)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(34;"Agreement Period Length";Integer)
        {
            BlankZero = true;
        }
        field(35;"Renewed Agreement";Boolean)
        {
            Editable = false;
        }
        field(36;"Original Agreement No.";Code[20])
        {
        }
        field(37;"Original Agreement Type";Option)
        {
            OptionCaption = 'Lease,Sale';
            OptionMembers = Lease,Sale;
        }
        field(38;"Transferred Agreement";Boolean)
        {
            Editable = false;
        }
        field(39;"Agreement Renewed";Boolean)
        {
        }
        field(40;"Agreement Transferred";Boolean)
        {
        }
        field(41;"Fit Out Period";DateFormula)
        {

            trigger OnValidate()
            begin
                ValidateFitOutDate;
            end;
        }
        field(42;"Fit Out Start Date";Date)
        {

            trigger OnValidate()
            begin
                ValidateFitOutDate;
            end;
        }
        field(43;"Fit Out End Date";Date)
        {
            Editable = false;
        }
        field(44;"Primary Premise Name";Text[50])
        {
            Editable = false;
        }
        field(45;"Currency Factor";Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0:15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                IF "Currency Factor" <> xRec."Currency Factor" THEN
                  UpdateAgreementLines;
            end;
        }
        field(46;"Total Original Amount(LCY)";Decimal)
        {
            CalcFormula = Sum("Agreement Line"."Amount (LCY)" WHERE (Agreement No.=FIELD(No.),
                                                                     Agreement Type=FIELD(Agreement Type),
                                                                     Sales Representative=FIELD(Sales Representative),
                                                                     Signature Date=FIELD(Signature Date)));
            FieldClass = FlowField;
        }
        field(47;"Premise Blocked";Boolean)
        {
        }
        field(48;"Formal Agreement";Boolean)
        {
        }
        field(49;"Long Term Agreement";Boolean)
        {
            Editable = false;

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(50;"Store Opening Date";Date)
        {

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(51;"LT Agreement Expiry Date";Date)
        {
            Caption = 'LT Agrmt. Expiry Date';

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status","Approval Status"::Open);
            end;
        }
        field(52;Closed;Boolean)
        {
            Editable = false;
        }
        field(53;"Pre-Close";Boolean)
        {
            Description = 'DP6.01.02';
            Editable = false;
        }
        field(54;Brand;Text[30])
        {
            Description = 'Lals-05APR22';
        }
        field(55;"Mall/Premise Name";Text[100])
        {
            Description = 'Lals-05APR22';
        }
        field(56;"Trade Lic. Start Date";Date)
        {
            Description = 'Lals-05APR22';
        }
        field(57;"Trade Lic. End Date";Date)
        {
            Description = 'Lals-05APR22';
        }
        field(58;"Ejari Start Date";Date)
        {
            Description = 'Lals-05APR22';
        }
        field(59;"Ejari End Date";Date)
        {
            Description = 'Lals-05APR22';
        }
        field(60;"Security Deposit";Decimal)
        {
            Description = 'Lals-05APR22';
            MinValue = 0;
        }
        field(61;"Fitout Deposit";Decimal)
        {
            Description = 'Lals-05APR22';
            MinValue = 0;
        }
        field(62;"Percentage Rent";Text[50])
        {
            Description = 'Lals-05APR22';
        }
        field(63;"Exit Clause";Text[50])
        {
            Description = 'Lals-05APR22';
        }
        field(64;"Rent Commencement Date";Date)
        {
            Description = 'Lals-05APR22';
        }
    }

    keys
    {
        key(Key1;"Agreement Type","No.")
        {
            Clustered = true;
        }
        key(Key2;"Client Segment","Agreement Status")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AgreementLineRec: Record "Agreement Line";
        PaymentScheduleLineRec: Record "Payment Schedule Lines";
        AgreementPremiseRec: Record "Agreement Premise Relation";
    begin
        TESTFIELD("Approval Status","Approval Status"::Open);
        CheckAgreementInvoice;

        AgreementPremiseRec.RESET;
        AgreementPremiseRec.SETRANGE("Agreement No.","No.");
        AgreementPremiseRec.SETFILTER("Premise No.",'<>%1','');
        IF AgreementPremiseRec.FINDFIRST THEN
          ERROR(Text002,"Agreement Type","No.");

        UpdatePremiseAgreementDetails(1);

        PaymentScheduleLineRec.RESET;
        PaymentScheduleLineRec.SETRANGE("Agreement Type","Agreement Type");
        PaymentScheduleLineRec.SETRANGE("Agreement No.","No.");
        PaymentScheduleLineRec.DELETEALL(TRUE);

        AgreementLineRec.RESET;
        AgreementLineRec.SETRANGE("Agreement Type","Agreement Type");
        AgreementLineRec.SETRANGE("Agreement No.","No.");
        AgreementLineRec.DELETEALL(TRUE);
        DimMgt.DeleteDocDim(DATABASE::"Agreement Header","Agreement Type","No.",0);
    end;

    trigger OnInsert()
    begin
        PremiseMgt.GET;
        IF "No." = '' THEN BEGIN
          PremiseMgt.TESTFIELD(Agreement);
          NoSeriesMgt.InitSeries(PremiseMgt.Agreement,xRec."No. Series",0D,"No.","No. Series");
        END;

        DimMgt.InsertDocDim(DATABASE::"Agreement Header","Agreement Type","No.",0,"Global Dimension 1 Code","Global Dimension 2 Code");

        "Formal Agreement" := TRUE;
    end;

    trigger OnModify()
    var
        AgreementLine: Record "Agreement Line";
    begin
        IF ("Global Dimension 1 Code" <> xRec."Global Dimension 1 Code") OR
           ("Global Dimension 2 Code" <> xRec."Global Dimension 2 Code") THEN BEGIN
           AgreementLine.RESET;
           AgreementLine.SETRANGE("Agreement Type","Agreement Type");
           AgreementLine.SETRANGE("Agreement No.","No.");
           IF AgreementLine.FINDFIRST THEN REPEAT
             AgreementLine.VALIDATE("Global Dimension 1 Code","Global Dimension 1 Code");
             AgreementLine.VALIDATE("Global Dimension 2 Code","Global Dimension 2 Code");
             AgreementLine.MODIFY;
           UNTIL AgreementLine.NEXT = 0;
        END;

        UpdateAgreementLines;

        TESTFIELD("Premise Blocked",FALSE);
    end;

    trigger OnRename()
    begin
        TESTFIELD("Approval Status","Approval Status"::Open);
    end;

    var
        PremiseMgt: Record "Premise Management Setup";
        NoSeriesMgt: Codeunit 396;
        DimMgt: Codeunit 408;
        PostCode: Record "Post Code";
        AgreementPremise: Record "Agreement Premise Relation";
        recPremise: Record Premise;
        Text001: Label 'Email Address %1 is not associated with a domain';
        Text002: Label 'Premise(s) are linked with Agreement Type %1 No. %2';
        Text003: Label 'Invoice(s) have been generated for Agreement Type : %1 Agreement No. : %2. You cannot remove Premise %3.';
        Text004: Label 'Posted Invoice(s) exists for Agreement Type %1 Agreement No. %2';
        Text005: Label 'Invoice(s) have been generated for Agreement Type %1 Agreement No.';
        Text006: Label 'Agreement Status is closed for Agreement Type : %1 No. : %2';
        Text33016802: Label 'Do you want to change the Agreement Status of Agreement Type %1 No. %2  from %3 to %4?';
        Text33016807: Label 'Premise/Sub Premise  %1 is already booked with an agreement = %2 with Agreement status = %3';
        Text33016809: Label 'You cannot remove Premise / Sub Premise from header as agreement Lines exists';
        Text33016810: Label 'You cannot make any change as Premise/Sub Premise %1 is blocked';
        Text33016870: Label 'Agreement No. %1  is %2';
        Text33016871: Label 'You are not allowed for Pre-Closure';
        Text33016872: Label 'Do you want to Pre-Close Agreement No. %1?';
        Text33016873: Label 'You cannot close Agreement with balance amount of %1';
        Text33016874: Label 'Agreement %1 is not linked with any premise';
 
    procedure AssistEdit(OldAgreementRec: Record "Agreement Header"): Boolean
    var
        AgreementRec: Record "Agreement Header";
    begin
        PremiseMgt.GET;
        PremiseMgt.TESTFIELD(Agreement);
        IF NoSeriesMgt.SelectSeries(PremiseMgt.Agreement,OldAgreementRec."No. Series","No. Series") THEN BEGIN
          NoSeriesMgt.SetSeries("No.");
          EXIT(TRUE);
        END;
    end;
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    var
        ChangeLogMgt: Codeunit 423;
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
        IF "No." <> '' THEN BEGIN
          DimMgt.SaveDocDim(
            DATABASE::"Agreement Header","Agreement Type","No.",0,FieldNumber,ShortcutDimCode);
          xRecRef.GETTABLE(xRec);
          MODIFY;
          RecRef.GETTABLE(Rec);
          ChangeLogMgt.LogModification(RecRef,xRecRef);
        END ELSE
          DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
    end;
 
    procedure UpdateAgreementLines()
    var
        AgreementLine: Record "Agreement Line";
    begin
        AgreementLine.RESET;
        AgreementLine.SETRANGE("Agreement Type","Agreement Type");
        AgreementLine.SETRANGE("Agreement No.","No.");
        IF AgreementLine.FINDFIRST THEN REPEAT
          AgreementLine.VALIDATE("Payment Term Code","Payment Terms Code");
          AgreementLine.VALIDATE("Sales Representative","Sales Representative");
          AgreementLine.VALIDATE("Signature Date","Signature Date");
          AgreementLine.VALIDATE("Currency Code","Currency Code");
          AgreementLine.MODIFY(TRUE);
        UNTIL AgreementLine.NEXT = 0;
    end;
 
    procedure ShowDocumentDimension()
    var
        DocDim: Record "Document Dimension";
        DocDims: Form "546";
    begin
        DocDim.RESET;
        DocDim.SETRANGE("Table ID",DATABASE::"Agreement Header");
        DocDim.SETRANGE("Document No.","No.");
        DocDim.SETRANGE("Line No.",0);
        DocDims.SETTABLEVIEW(DocDim);
        DocDims.RUNMODAL;
        GET("Agreement Type","No.");
    end;
 
    procedure UpdatePremiseAgreementDetails(AgreementDetails: Option Modify,Delete)
    var
        AgreementPremise: Record "Agreement Premise Relation";
        PremiseRec: Record Premise;
        ClientRec: Record Customer;
    begin
        IF AgreementDetails = AgreementDetails::Delete THEN BEGIN
          ValidateAgreementClient(FALSE);
          AgreementPremise.RESET;
          AgreementPremise.SETRANGE("Agreement No.","No.");
          IF AgreementPremise.FINDSET THEN
            AgreementPremise.DELETEALL;
        END;
    end;
 
    procedure ValidateAgreementClient(ClientChk: Boolean)
    var
        AgreementPremiseRec: Record "Agreement Premise Relation";
        PremiseRec: Record Premise;
        ClientRec: Record Customer;
    begin
        AgreementPremiseRec.RESET;
        AgreementPremiseRec.SETRANGE("Agreement No.","No.");
        IF AgreementPremiseRec.FINDSET THEN
          REPEAT
          IF PremiseRec.GET(AgreementPremiseRec."Premise No.") THEN BEGIN
              PremiseRec."Client No." := '';
              PremiseRec."Client Name" := '';
              PremiseRec."Client Mobile No." := '';
              PremiseRec."Client Phone No." := '';
              PremiseRec."Client E-Mail" := '';
              PremiseRec."Global Dimension 1 Code" := '';
              PremiseRec."Global Dimension 2 Code" := '';
              PremiseRec."Agreement Type" := 0;
              PremiseRec."Agreement No." := '';
              PremiseRec."Premise Status" := 0;
            PremiseRec.MODIFY(TRUE);
          END;
        UNTIL AgreementPremiseRec.NEXT = 0;
    end;
 
    procedure ValidateFitOutDate()
    begin
        IF (FORMAT("Fit Out Period") <> '') AND ("Fit Out Start Date" <> 0D) THEN BEGIN
          "Fit Out End Date" := CALCDATE("Fit Out Period","Fit Out Start Date");
          "Fit Out End Date" := CALCDATE('-1D',"Fit Out End Date");
        END ELSE
          "Fit Out End Date" := 0D;
    end;
 
    procedure ValidateLinePremise(AgreementRec: Record "Agreement Header";PremiseCode: Code[20])
    var
        AgreementLineRec: Record "Agreement Line";
    begin
        AgreementLineRec.RESET;
        AgreementLineRec.SETRANGE("Agreement Type",AgreementRec."Agreement Type");
        AgreementLineRec.SETRANGE("Agreement No.",AgreementRec."No.");
        AgreementLineRec.SETFILTER("Element Type",'<>%1','');
        AgreementLineRec.SETRANGE("Premise No.",PremiseCode);
        IF AgreementLineRec.FINDFIRST THEN
          ERROR(Text33016809,PremiseCode)
    end;
 
    procedure UpdateAgreementLineDate()
    var
        AgreementLineRec: Record "Agreement Line";
    begin
        AgreementLineRec.RESET;
        AgreementLineRec.SETRANGE("Agreement Type","Agreement Type");
        AgreementLineRec.SETRANGE("Agreement No.","No.");
        IF AgreementLineRec.FINDSET THEN
          REPEAT
            AgreementLineRec."Start Date" := "Agreement Start Date";
            AgreementLineRec."End Date" := "Agreement End Date";
            AgreementLineRec.MODIFY;
          UNTIL AgreementLineRec.NEXT = 0;
    end;
 
    procedure CheckAgreementInvoice()
    var
        AgreementLineRec: Record "Agreement Line";
    begin
        AgreementLineRec.RESET;
        AgreementLineRec.SETRANGE("Agreement Type","Agreement Type");
        AgreementLineRec.SETRANGE("Agreement No.","No.");
        AgreementLineRec.SETFILTER("Element Type",'<>%1','');
        IF AgreementLineRec.FINDSET THEN
          REPEAT
            AgreementLineRec.CALCFIELDS("Posted Invoice","Unposted Invoice");
            IF AgreementLineRec."Unposted Invoice" <> 0 THEN
              ERROR(Text005,AgreementLineRec."Agreement Type",AgreementLineRec."Agreement No.");
            IF AgreementLineRec."Posted Invoice" <> 0 THEN
              ERROR(Text004,AgreementLineRec."Agreement Type",AgreementLineRec."Agreement No.");
          UNTIL AgreementLineRec.NEXT = 0;
    end;
 
    procedure UpdateClientDetails()
    var
        CustomerRec: Record Customer;
        AgreementLineRec: Record "Agreement Line";
    begin
        IF xRec."Client No." <> "Client No." THEN BEGIN
          IF "Agreement Status" = "Agreement Status"::Closed THEN
            ERROR(Text006,"Agreement Type","No.");

          IF xRec."Client No." <> '' THEN BEGIN
            AgreementLineRec.RESET;
            AgreementLineRec.SETRANGE("Agreement Type","Agreement Type");
            AgreementLineRec.SETRANGE("Agreement No.","No.");
            IF AgreementLineRec.FINDSET THEN
              REPEAT
                AgreementLineRec.CALCFIELDS("Posted Invoice","Unposted Invoice");
                IF AgreementLineRec."Unposted Invoice" > 0 THEN
                  ERROR(Text005,AgreementLineRec."Agreement Type",AgreementLineRec."Agreement No.");
                IF AgreementLineRec."Posted Invoice" > 0 THEN
                  ERROR(Text004,AgreementLineRec."Agreement Type",AgreementLineRec."Agreement No.");
              UNTIL AgreementLineRec.NEXT = 0;
          END;

          IF CustomerRec.GET("Client No.") THEN BEGIN
            AgreementLineRec.RESET;
            AgreementLineRec.SETRANGE("Agreement Type","Agreement Type");
            AgreementLineRec.SETRANGE("Agreement No.","No.");
            IF AgreementLineRec.FINDSET THEN
              REPEAT
                AgreementLineRec.VALIDATE("Client No.","Client No.");
                AgreementLineRec.MODIFY;
              UNTIL AgreementLineRec.NEXT = 0;
          END ELSE BEGIN
            AgreementLineRec.RESET;
            AgreementLineRec.SETRANGE("Agreement Type","Agreement Type");
            AgreementLineRec.SETRANGE("Agreement No.","No.");
            IF AgreementLineRec.FINDSET THEN
              REPEAT
                AgreementLineRec.VALIDATE("Client No.",'');
                AgreementLineRec.MODIFY;
              UNTIL AgreementLineRec.NEXT = 0;
          END;
        END;
    end;
 
    procedure UpdateCurrencyFactor()
    var
        CurrencyDate: Date;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        IF "Currency Code" <> '' THEN
         BEGIN
            CurrencyDate := WORKDATE;
            "Currency Factor" := 1/CurrExchRate.ExchangeRate(CurrencyDate,"Currency Code");
           END ELSE
          "Currency Factor" := 0;
    end;
 
    procedure ConfirmUpdateCurrencyFactor()
    var
        HideValidationDialog: Boolean;
        Confirmed: Boolean;
        Text021: Label 'Do you want to update the exchange rate?';
    begin
        HideValidationDialog:=TRUE;
        IF HideValidationDialog THEN
          Confirmed := TRUE
        ELSE
          Confirmed := CONFIRM(Text021,FALSE);
        IF Confirmed THEN
          VALIDATE("Currency Factor")
        ELSE
          "Currency Factor" := xRec."Currency Factor";
    end;
 
    procedure RecreateAgreementLines()
    var
        AgreementLine: Record "Agreement Line";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        AgreementLineTmp: Record "Agreement Line" temporary;
    begin

        IF Currency.GET("Currency Code") THEN;
        IF AgreementLinesExist THEN
        BEGIN
        AgreementLine.SETRANGE("Agreement Type","Agreement Type");
        AgreementLine.SETRANGE("Agreement No.","No.");
        IF AgreementLine.FINDSET THEN
          REPEAT
          AgreementLine.CALCFIELDS("Unposted Invoice","Posted Invoice Amt.");
           AgreementLine.TESTFIELD(AgreementLine."Unposted Invoice",0);
           AgreementLine.TESTFIELD(AgreementLine."Posted Invoice Amt.",0);
          UNTIL AgreementLine.NEXT=0;

        AgreementLine.RESET;

        AgreementLine.SETRANGE(AgreementLine."Agreement Type","Agreement Type");
        AgreementLine.SETRANGE("Agreement No.","No.");
        IF AgreementLine.FINDSET THEN
        REPEAT
        IF "Currency Code" <> '' THEN BEGIN
          AgreementLine."Amount (LCY)" :=
            ROUND(
              CurrExchRate.ExchangeAmtLCYToFCY(
                WORKDATE,"Currency Code",
                AgreementLine."Original Amount","Currency Factor"),
              Currency."Unit-Amount Rounding Precision")
        END ELSE
          AgreementLine."Amount (LCY)" := AgreementLine."Original Amount";
          AgreementLine.MODIFY;
          UNTIL AgreementLine.NEXT=0;
        END
    end;
 
    procedure AgreementLinesExist(): Boolean
    var
        AgreementLines: Record "Agreement Line";
    begin
        AgreementLines.RESET;
        AgreementLines.SETRANGE("Agreement Type","Agreement Type");
        AgreementLines.SETRANGE("Agreement No.","No.");
        EXIT(AgreementLines.FINDFIRST);
    end;
 
    procedure UpdateAgreementStatus()
    var
        AgreementStatusFrm: Form 33016852;
        AgmtStatus: Option New,Active,Cancelled,Closed;
        PremiseApprovalMgt: Codeunit 33016803;
        AgreementRec: Record "Agreement Header";
        OldStatus: Option New,Active,Cancel,Close;
        AgreementRec1: Record "Agreement Header";
        AgrmtBalanceAmt: Decimal;
    begin
        CLEAR(PremiseApprovalMgt);
        CLEAR(AgreementStatusFrm);
        AgrmtBalanceAmt := 0; //DP6.01.02

        IF AgreementRec.GET("Agreement Type","No.") THEN BEGIN
          IF AgreementRec."Agreement Status" IN [AgreementRec."Agreement Status"::New,AgreementRec."Agreement Status"::Active] THEN
          BEGIN
            AgreementStatusFrm.SetStatus(AgreementRec."Agreement Status");
            OldStatus := AgreementRec."Agreement Status";
            IF AgreementStatusFrm.RUNMODAL = ACTION::OK THEN BEGIN
              AgreementStatusFrm.GetStatus(AgmtStatus);
              CASE AgmtStatus OF
                AgmtStatus::New:
                  AgreementRec."Agreement Status" := AgreementRec."Agreement Status"::New;
                AgmtStatus::Active:
                  BEGIN
                    AgreementRec.TESTFIELD(AgreementRec."Approval Status",AgreementRec."Approval Status"::Released);
                    AgreementRec."Agreement Status" := AgreementRec."Agreement Status"::Active;
                  END;
                AgmtStatus::Cancelled:
                  BEGIN
                    AgreementRec."Agreement Status" := AgreementRec."Agreement Status"::Cancelled;
                    AgreementRec.Closed := TRUE;
                  END;
                AgmtStatus::Closed:
                  BEGIN
                    //DP6.01.02 START
                    AgrmtBalanceAmt := CheckAgrmtBalance;
                    //IF AgrmtBalanceAmt <> 0 THEN BEGIN//LALS
                    IF AgrmtBalanceAmt > 0 THEN BEGIN //LALS
                      IF AgreementRec."Pre-Close" THEN BEGIN
                        AgreementRec.TESTFIELD(AgreementRec."Approval Status",AgreementRec."Approval Status"::Released);
                        AgreementRec."Agreement Status" := AgreementRec."Agreement Status"::Closed;
                        AgreementRec.Closed := TRUE;
                      END ELSE
                        ERROR(Text33016873,AgrmtBalanceAmt);
                    END ELSE BEGIN
                    //DP6.01.02 STOP
                      AgreementRec.TESTFIELD(AgreementRec."Approval Status",AgreementRec."Approval Status"::Released);
                      AgreementRec."Agreement Status" := AgreementRec."Agreement Status"::Closed;
                      AgreementRec.Closed := TRUE;
                    //DP6.01.02 START
                    END;
                  END;
                    //DP6.01.02 STOP
              END;
              IF AgreementRec."Agreement Status" <> OldStatus THEN BEGIN
                IF CONFIRM(Text33016802,FALSE,AgreementRec."Agreement Type",AgreementRec."No.",OldStatus,
                  AgreementRec."Agreement Status") THEN BEGIN
                  AgreementRec1 := AgreementRec;
                  AgreementRec1.MODIFY;
                  UpdatePremisesStatus(AgreementRec1);
                END;
              END;
            END;
          END ELSE
            ERROR(Text33016870,AgreementRec."No.",AgreementRec."Agreement Status");
        END;
    end;

    procedure UpdatePremisesStatus(AgrmtRec: Record "Agreement Header")
    var
        AgrmtPremiseRec: Record "Agreement Premise Relation";
        PremiseRec: Record Premise;
        ClientRec: Record Customer;
        AgrmtPremiseRec1: Record "Agreement Premise Relation";
        SubPremiseRec: Record Premise;
        SubPremiseRec1: Record Premise;
        AgrmtPremiseRec2: Record "Agreement Premise Relation";
    begin
        AgrmtPremiseRec.RESET;
        AgrmtPremiseRec.SETRANGE("Agreement No.",AgrmtRec."No.");
        AgrmtPremiseRec.SETFILTER("Premise No.",'<>%1','');
        IF AgrmtPremiseRec.FINDSET THEN BEGIN
          REPEAT
            IF PremiseRec.GET(AgrmtPremiseRec."Premise No.") THEN BEGIN
              IF AgrmtRec."Agreement Status" = AgrmtRec."Agreement Status"::Active THEN BEGIN
                IF NOT PremiseRec."Allow Multiple Agreements" THEN BEGIN
                  CheckPremisePreBooked(PremiseRec."No.",AgrmtRec."No.");

                  PremiseRec."Client No." := AgrmtRec."Client No.";
                  ClientRec.GET("Client No.");
                  PremiseRec."Agreement No." := AgrmtRec."No.";
                  PremiseRec."Client Name" := ClientRec.Name;
                  PremiseRec."Client Mobile No." := ClientRec."Telex No.";
                  PremiseRec."Client Phone No." := ClientRec."Phone No.";
                  PremiseRec."Client E-Mail" := ClientRec."E-Mail";
                  PremiseRec."Global Dimension 1 Code" := AgrmtRec."Global Dimension 1 Code";
                  PremiseRec."Global Dimension 2 Code" := AgrmtRec."Global Dimension 2 Code";
                  PremiseRec."Pre-Booked" := FALSE;
                  PremiseRec."Pre-Booked Agreement No." := '';
                END;
                PremiseRec.TESTFIELD(PremiseRec.Blocked,FALSE);
                IF AgrmtRec."Agreement Type" = AgrmtRec."Agreement Type"::Lease THEN BEGIN
                  PremiseRec."Agreement Type" := PremiseRec."Agreement Type"::Lease;
                  PremiseRec."Premise Status" := PremiseRec."Premise Status"::"On Lease";
                END ELSE BEGIN
                  PremiseRec."Agreement Type" := PremiseRec."Agreement Type"::Sale;
                  PremiseRec."Premise Status" := PremiseRec."Premise Status"::Sold;
                END;
              END ELSE BEGIN
                IF AgrmtRec."Agreement Status" IN [AgrmtRec."Agreement Status"::Cancelled,AgrmtRec."Agreement Status"::Closed] THEN
                  BEGIN
                   IF PremiseRec."Allow Multiple Agreements" THEN BEGIN
                      AgrmtPremiseRec2.RESET;
                      AgrmtPremiseRec2.SETRANGE("Premise No.",PremiseRec."No.");
                      AgrmtPremiseRec2.SETFILTER("Agreement No.",'<>%1',AgrmtRec."No.");
                      AgrmtPremiseRec2.SETRANGE("Agreement Status",AgrmtPremiseRec2."Agreement Status"::Active);
                      IF AgrmtPremiseRec2.FINDFIRST THEN BEGIN
                        IF AgrmtPremiseRec2."Agreement Type" = AgrmtPremiseRec2."Agreement Type"::Lease THEN
                          PremiseRec."Premise Status" := PremiseRec."Premise Status"::"On Lease"
                        ELSE
                          PremiseRec."Premise Status" := PremiseRec."Premise Status"::Sold;
                      END ELSE
                        AgrmtPremiseRec2.SETRANGE("Agreement Status",AgrmtPremiseRec2."Agreement Status"::New);
                        IF AgrmtPremiseRec2.FINDFIRST THEN
                          PremiseRec."Premise Status" := PremiseRec."Premise Status"::Booked
                        ELSE
                          PremiseRec."Premise Status" := PremiseRec."Premise Status"::Vacant
                   END ELSE BEGIN
                     IF PremiseRec."Pre-Booked" THEN BEGIN
                       IF PremiseRec."Pre-Booked Agreement No." <> AgrmtRec."No." THEN BEGIN
                         PremiseRec."Premise Status" := PremiseRec."Premise Status"::Booked;
                         PremiseRec."Client No." := '';
                         PremiseRec."Client Name" := '';
                         PremiseRec."Client Mobile No." := '';
                         PremiseRec."Client Phone No." := '';
                         PremiseRec."Client E-Mail" := '';
                         PremiseRec."Global Dimension 1 Code" := '';
                         PremiseRec."Global Dimension 2 Code" := '';
                         PremiseRec."Agreement Type" := 0;
                         PremiseRec."Agreement No." := '';
                       END;
                       PremiseRec."Pre-Booked" := FALSE;
                       PremiseRec."Pre-Booked Agreement No." := '';
                     END ELSE BEGIN
                       PremiseRec."Client No." := '';
                       PremiseRec."Client Name" := '';
                       PremiseRec."Client Mobile No." := '';
                       PremiseRec."Client Phone No." := '';
                       PremiseRec."Client E-Mail" := '';
                       PremiseRec."Global Dimension 1 Code" := '';
                       PremiseRec."Global Dimension 2 Code" := '';
                       PremiseRec."Agreement Type" := 0;
                       PremiseRec."Agreement No." := '';
                       PremiseRec."Premise Status" := 0;
                     END;
                   END;
                 END;
              END;
              PremiseRec.MODIFY;
              //Update Subpremises with Premise status
              IF PremiseRec."Premise/Sub-Premise" = PremiseRec."Premise/Sub-Premise"::Premise THEN BEGIN
                SubPremiseRec.RESET;
                SubPremiseRec.SETCURRENTKEY("Sub-Premise of Premise","Premise/Sub-Premise");
                SubPremiseRec.SETRANGE("Sub-Premise of Premise",PremiseRec."No.");
                SubPremiseRec.SETRANGE("Premise/Sub-Premise",SubPremiseRec."Premise/Sub-Premise"::"Sub-Premise");
                IF SubPremiseRec.FINDSET THEN REPEAT
                  SubPremiseRec1 := SubPremiseRec;
                  SubPremiseRec1."Premise Status" := PremiseRec."Premise Status";
                  SubPremiseRec1.MODIFY;
                UNTIL SubPremiseRec.NEXT = 0;
              END;
            END;
            //Update Agreement status in Agreement Premise Relation
            AgrmtPremiseRec1 := AgrmtPremiseRec;
            AgrmtPremiseRec1."Agreement Status" := AgrmtRec."Agreement Status";
            AgrmtPremiseRec1.MODIFY;

          UNTIL AgrmtPremiseRec.NEXT = 0;
        //DP6.01.03 START
        //END;
        END ELSE
          ERROR(Text33016874,AgrmtRec."No.");
        //DP6.01.03 STOP
    end;

   
    procedure CheckPremisePreBooked(PremiseNo: Code[20];AgrmtNo: Code[20])
    var
        AgrmtPreRelation: Record "Agreement Premise Relation";
        AgrmtHdr: Record "Agreement Header";
    begin
        AgrmtPreRelation.RESET;
        AgrmtPreRelation.SETRANGE("Premise No.",PremiseNo);
        AgrmtPreRelation.SETFILTER("Agreement No.",'<>%1',AgrmtNo);
        AgrmtPreRelation.SETRANGE("Agreement Status",AgrmtPreRelation."Agreement Status"::New);
        IF AgrmtPreRelation.FINDFIRST THEN BEGIN
          ERROR(Text33016807,PremiseNo,AgrmtPreRelation."Agreement No.",AgrmtPreRelation."Agreement Status");
        END;

        AgrmtPreRelation.RESET;
        AgrmtPreRelation.SETRANGE("Premise No.",PremiseNo);
        AgrmtPreRelation.SETFILTER("Agreement No.",'<>%1',AgrmtNo);
        AgrmtPreRelation.SETRANGE("Agreement Status",AgrmtPreRelation."Agreement Status"::Active);
        IF AgrmtPreRelation.FINDFIRST THEN BEGIN
          ERROR(Text33016807,PremiseNo,AgrmtPreRelation."Agreement No.",AgrmtPreRelation."Agreement Status");
        END;
    end;

  
    procedure CheckAnyPremiseBlocked()
    var
        AgrmtPreRelation: Record "Agreement Premise Relation";
        PremiseBlocked: Record Premise;
    begin
        IF "Premise Blocked" THEN BEGIN
          AgrmtPreRelation.RESET;
          AgrmtPreRelation.SETRANGE("Agreement No.","No.");
          AgrmtPreRelation.SETFILTER("Premise No.",'<>%1','');
          IF AgrmtPreRelation.FINDSET THEN BEGIN
            REPEAT
              PremiseBlocked.GET(AgrmtPreRelation."Premise No.");
              IF PremiseBlocked.Blocked THEN
                ERROR(Text33016810,AgrmtPreRelation."Premise No.");
            UNTIL AgrmtPreRelation.NEXT = 0;
          END;
        END;
    end;

    
    procedure EnableLongTermAgreement()
    var
        AgrmtHdr: Record "Agreement Header";
    begin
        TESTFIELD("Agreement Status","Agreement Status"::New);
        TESTFIELD("Long Term Agreement",FALSE);
        AgrmtHdr.GET("Agreement Type","No.");
        AgrmtHdr.VALIDATE("Long Term Agreement",TRUE);
        AgrmtHdr.MODIFY(TRUE);
    end;
 
    procedure DisableLongTermAgreement()
    var
        AgrmtHdr: Record "Agreement Header";
    begin
        TESTFIELD("Agreement Status","Agreement Status"::New);
        TESTFIELD("Long Term Agreement",TRUE);
        AgrmtHdr.GET("Agreement Type","No.");
        AgrmtHdr.VALIDATE("Long Term Agreement",FALSE);
        AgrmtHdr."LT Agreement Expiry Date" := 0D;
        AgrmtHdr.MODIFY(TRUE);
    end;
 
    procedure AgreementPreClosure()
    var
        UserSetup: Record "User Setup";
        AgrmtHdr: Record "Agreement Header";
    begin
        //DP6.01.02 START
        TESTFIELD("Pre-Close",FALSE);
        TESTFIELD("Approval Status","Approval Status"::Released);
        UserSetup.GET(USERID);
        IF UserSetup."Allow Pre-Closure" THEN BEGIN
          IF CONFIRM(Text33016872,FALSE,"No.") THEN BEGIN
            AgrmtHdr.GET("Agreement Type","No.");
            AgrmtHdr."Pre-Close" := TRUE;
            AgrmtHdr.MODIFY;
          END;
        END ELSE
          ERROR(Text33016871);
        //DP6.01.02 STOP
    end;

    procedure CheckAgrmtBalance(): Decimal
    var
        AgrmtLines: Record "Agreement Line";
        TotalAgrmtBalance: Decimal;
    begin
        //DP6.01.02 START
        AgrmtLines.SETRANGE("Agreement Type","Agreement Type");
        AgrmtLines.SETRANGE("Agreement No.","No.");
        IF AgrmtLines.FINDSET THEN REPEAT
          TotalAgrmtBalance += AgrmtLines."Balanced Amount";
        UNTIL AgrmtLines.NEXT = 0;
        EXIT(TotalAgrmtBalance);
        //DP6.01.02 STOP
    end;
}

