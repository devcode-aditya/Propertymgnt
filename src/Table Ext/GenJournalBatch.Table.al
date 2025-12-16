table 232 "Gen. Journal Batch"
{
    // DP = changes made by DVS
    // 
    // Code          Date          Name          Description
    // APNT-HR1.0    12.11.13      Sangeeta      Added Payroll option in Template Type field for HR & Payroll Customization.
    // APNT-10708    16.05.16      Saajid        Added field for Docuemnt No. Series

    Caption = 'Gen. Journal Batch';
    DataCaptionFields = Name, Description;
    LookupFormID = Form251;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Gen. Journal Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(4; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";

            trigger OnValidate()
            begin
                IF "Reason Code" <> xRec."Reason Code" THEN BEGIN
                    ModifyLines(FIELDNO("Reason Code"));
                    MODIFY;
                END;
            end;
        }
        field(5; "Bal. Account Type"; Option)
        {
            Caption = 'Bal. Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        field(6; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF (Bal.Account Type=CONST(G/L Account)) "G/L Account"
                            ELSE IF (Bal. Account Type=CONST(Customer)) Customer
                            ELSE IF (Bal. Account Type=CONST(Vendor)) Vendor
                            ELSE IF (Bal. Account Type=CONST(Bank Account)) "Bank Account"
                            ELSE IF (Bal. Account Type=CONST(Fixed Asset)) "Fixed Asset";

            trigger OnValidate()
            begin
                IF "Bal. Account Type" = "Bal. Account Type"::"G/L Account" THEN
                  CheckGLAcc("Bal. Account No.");
            end;
        }
        field(7;"No. Series";Code[10])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                IF "No. Series" <> '' THEN BEGIN
                  GenJnlTemplate.GET("Journal Template Name");
                  IF GenJnlTemplate.Recurring THEN
                    ERROR(
                      Text000,
                      FIELDCAPTION("Posting No. Series"));
                  IF "No. Series" = "Posting No. Series" THEN
                    VALIDATE("Posting No. Series",'');
                END;
            end;
        }
        field(8;"Posting No. Series";Code[10])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                IF ("Posting No. Series" = "No. Series") AND ("Posting No. Series" <> '') THEN
                  FIELDERROR("Posting No. Series",STRSUBSTNO(Text001,"Posting No. Series"));
                ModifyLines(FIELDNO("Posting No. Series"));
                MODIFY;
            end;
        }
        field(9;"Copy VAT Setup to Jnl. Lines";Boolean)
        {
            Caption = 'Copy VAT Setup to Jnl. Lines';
            InitValue = true;
        }
        field(10;"Allow VAT Difference";Boolean)
        {
            Caption = 'Allow VAT Difference';

            trigger OnValidate()
            begin
                IF "Allow VAT Difference" THEN BEGIN
                  GenJnlTemplate.GET("Journal Template Name");
                  GenJnlTemplate.TESTFIELD("Allow VAT Difference",TRUE);
                END;
            end;
        }
        field(21;"Template Type";Option)
        {
            CalcFormula = Lookup("Gen. Journal Template".Type WHERE (Name=FIELD(Journal Template Name)));
            Caption = 'Template Type';
            Description = 'HR1.0';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'General,Sales,Purchases,Cash Receipts,Payments,Assets,Intercompany,Jobs,Payroll';
            OptionMembers = General,Sales,Purchases,"Cash Receipts",Payments,Assets,Intercompany,Jobs,Payroll;
        }
        field(22;Recurring;Boolean)
        {
            CalcFormula = Lookup("Gen. Journal Template".Recurring WHERE (Name=FIELD(Journal Template Name)));
            Caption = 'Recurring';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50000;"Document No. Series";Code[20])
        {
            TableRelation = "No. Series";
        }
        field(33016800;"Post Rcpt. Journal Batch";Code[10])
        {
            Description = 'DP6.01.01';

            trigger OnLookup()
            var
                GenJnlBatchRec: Record "232";
                GenJnlBatchForm: Form "251";
                GenJournalTemplateRec: Record "80";
            begin
                //DP6.01.01 START
                IF GenJournalTemplateRec.GET("Journal Template Name") THEN BEGIN
                  IF NOT GenJournalTemplateRec."Receipt Journal" THEN
                    ERROR(Text33016831,GenJournalTemplateRec.Name,Name);
                END;

                GenJournalTemplateRec.RESET;
                GenJournalTemplateRec.SETRANGE("Post Receipt Journal",TRUE);
                IF GenJournalTemplateRec.FINDFIRST THEN BEGIN
                  CLEAR(GenJnlBatchForm);
                  GenJnlBatchRec.RESET;
                  GenJnlBatchRec.SETRANGE("Journal Template Name",GenJournalTemplateRec.Name);
                  GenJnlBatchForm.SETTABLEVIEW(GenJnlBatchRec);
                  GenJnlBatchForm.LOOKUPMODE(TRUE);
                  IF GenJnlBatchForm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                     GenJnlBatchForm.GETRECORD(GenJnlBatchRec);
                     IF GenJnlBatchRec.Name <> '' THEN
                      "Post Rcpt. Journal Batch" := GenJnlBatchRec.Name;
                  END;
                END;
                //DP6.01.01 STOP
            end;
        }
    }

    keys
    {
        key(Key1;"Journal Template Name",Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        GenJnlAlloc.SETRANGE("Journal Template Name","Journal Template Name");
        GenJnlAlloc.SETRANGE("Journal Batch Name",Name);
        GenJnlAlloc.DELETEALL;
        GenJnlLine.SETRANGE("Journal Template Name","Journal Template Name");
        GenJnlLine.SETRANGE("Journal Batch Name",Name);
        GenJnlLine.DELETEALL(TRUE);
    end;

    trigger OnInsert()
    begin
        LOCKTABLE;
        GenJnlTemplate.GET("Journal Template Name");
        IF GenJnlTemplate."Copy VAT Setup to Jnl. Lines" = FALSE THEN
          "Copy VAT Setup to Jnl. Lines" := FALSE;
    end;

    var
        Text000: Label 'Only the %1 field can be filled in on recurring journals.';
        Text001: Label 'must not be %1';
        GenJnlTemplate: Record "80";
        GenJnlLine: Record "81";
        GenJnlAlloc: Record "221";
        Text33016831: Label 'Receipt Journal must be true for journal template = %1 and journal batch = %2 ';
 
    procedure SetupNewBatch()
    begin
        GenJnlTemplate.GET("Journal Template Name");
        "Bal. Account Type" := GenJnlTemplate."Bal. Account Type";
        "Bal. Account No." := GenJnlTemplate."Bal. Account No.";
        "No. Series" := GenJnlTemplate."No. Series";
        "Posting No. Series" := GenJnlTemplate."Posting No. Series";
        "Reason Code" := GenJnlTemplate."Reason Code";
        "Copy VAT Setup to Jnl. Lines" := GenJnlTemplate."Copy VAT Setup to Jnl. Lines";
        "Allow VAT Difference" := GenJnlTemplate."Allow VAT Difference";
    end;

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "15";
    begin
        IF AccNo <> '' THEN BEGIN
          GLAcc.GET(AccNo);
          GLAcc.CheckGLAcc;
          GLAcc.TESTFIELD("Direct Posting",TRUE);
        END;
    end;
 
    procedure ModifyLines(i: Integer)
    begin
        GenJnlLine.LOCKTABLE;
        GenJnlLine.SETRANGE("Journal Template Name","Journal Template Name");
        GenJnlLine.SETRANGE("Journal Batch Name",Name);
        IF GenJnlLine.FIND('-') THEN
          REPEAT
            CASE i OF
              FIELDNO("Reason Code"):
                GenJnlLine.VALIDATE("Reason Code","Reason Code");
              FIELDNO("Posting No. Series"):
                GenJnlLine.VALIDATE("Posting No. Series","Posting No. Series");
            END;
            GenJnlLine.MODIFY(TRUE);
          UNTIL GenJnlLine.NEXT = 0;
    end;
}

