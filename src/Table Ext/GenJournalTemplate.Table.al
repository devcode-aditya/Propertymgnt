table 80 "Gen. Journal Template"
{
    // LS = changes made by LS Retail
    // DP = changes made by DVS
    // APNT-HR1.0    12.11.13    Sangeeta           Added code and option in Type &
    //                                              Bal. Account Type fields for HR and Payroll Customization

    Caption = 'Gen. Journal Template';
    LookupFormID = Form250;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(5; "Test Report ID"; Integer)
        {
            Caption = 'Test Report ID';
            TableRelation = Object.ID WHERE(Type = CONST(Report));
        }
        field(6; "Form ID"; Integer)
        {
            Caption = 'Form ID';
            TableRelation = Object.ID WHERE(Type = CONST(Form));

            trigger OnValidate()
            begin
                IF "Form ID" = 0 THEN
                    VALIDATE(Type);
            end;
        }
        field(7; "Posting Report ID"; Integer)
        {
            Caption = 'Posting Report ID';
            TableRelation = Object.ID WHERE(Type = CONST(Report));
        }
        field(8; "Force Posting Report"; Boolean)
        {
            Caption = 'Force Posting Report';
        }
        field(9; Type; Option)
        {
            Caption = 'Type';
            Description = 'HR1.0';
            OptionCaption = 'General,Sales,Purchases,Cash Receipts,Payments,Assets,Intercompany,Jobs,Payroll';
            OptionMembers = General,Sales,Purchases,"Cash Receipts",Payments,Assets,Intercompany,Jobs,Payroll;

            trigger OnValidate()
            begin
                "Test Report ID" := REPORT::"General Journal - Test";
                "Posting Report ID" := REPORT::"G/L Register";
                SourceCodeSetup.GET;
                CASE Type OF
                    Type::General:
                        BEGIN
                            "Source Code" := SourceCodeSetup."General Journal";
                            "Form ID" := FORM::"General Journal";
                        END;
                    Type::Sales:
                        BEGIN
                            "Source Code" := SourceCodeSetup."Sales Journal";
                            "Form ID" := FORM::"Sales Journal";
                        END;
                    Type::Purchases:
                        BEGIN
                            "Source Code" := SourceCodeSetup."Purchase Journal";
                            "Form ID" := FORM::"Purchase Journal";
                        END;
                    Type::"Cash Receipts":
                        BEGIN
                            "Source Code" := SourceCodeSetup."Cash Receipt Journal";
                            "Form ID" := FORM::"Cash Receipt Journal";
                        END;
                    Type::Payments:
                        BEGIN
                            "Source Code" := SourceCodeSetup."Payment Journal";
                            "Form ID" := FORM::"Payment Journal";
                        END;
                    Type::Assets:
                        BEGIN
                            "Source Code" := SourceCodeSetup."Fixed Asset G/L Journal";
                            "Form ID" := FORM::"Fixed Asset G/L Journal";
                        END;
                    Type::Intercompany:
                        BEGIN
                            "Source Code" := SourceCodeSetup."IC General Journal";
                            "Form ID" := FORM::"IC General Journal";
                        END;
                    Type::Jobs:
                        BEGIN
                            "Source Code" := SourceCodeSetup."Job G/L Journal";
                            "Form ID" := FORM::"Job G/L Journal";
                        END;
                    //APNT-HR1.0
                    Type::Payroll:
                        BEGIN
                            "Source Code" := SourceCodeSetup."Payroll Journal";
                            "Form ID" := FORM::"Payroll Journal";
                        END;
                //APNT-HR1.0
                END;

                IF Recurring THEN
                    "Form ID" := FORM::"Recurring General Journal";
            end;
        }
        field(10; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";

            trigger OnValidate()
            begin
                GenJnlLine.SETRANGE("Journal Template Name", Name);
                GenJnlLine.MODIFYALL("Source Code", "Source Code");
                MODIFY;
            end;
        }
        field(11; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(12; Recurring; Boolean)
        {
            Caption = 'Recurring';

            trigger OnValidate()
            begin
                VALIDATE(Type);
                IF Recurring THEN
                    TESTFIELD("No. Series", '');
            end;
        }
        field(15; "Test Report Name"; Text[80])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE(Object Type=CONST(Report),
                                                                           Object ID=FIELD(Test Report ID)));
            Caption = 'Test Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16;"Form Name";Text[80])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE (Object Type=CONST(Form),
                                                                           Object ID=FIELD(Form ID)));
            Caption = 'Form Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17;"Posting Report Name";Text[80])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE (Object Type=CONST(Report),
                                                                           Object ID=FIELD(Posting Report ID)));
            Caption = 'Posting Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18;"Force Doc. Balance";Boolean)
        {
            Caption = 'Force Doc. Balance';
            InitValue = true;
        }
        field(19;"Bal. Account Type";Option)
        {
            Caption = 'Bal. Account Type';
            Description = 'HR1.0';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset,Employee';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset",Employee;

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        field(20;"Bal. Account No.";Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF (Bal. Account Type=CONST(G/L Account)) "G/L Account"
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
        field(21;"No. Series";Code[10])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                IF "No. Series" <> '' THEN BEGIN
                  IF Recurring THEN
                    ERROR(
                      Text000,
                      FIELDCAPTION("Posting No. Series"));
                  IF "No. Series" = "Posting No. Series" THEN
                    "Posting No. Series" := '';
                END;
            end;
        }
        field(22;"Posting No. Series";Code[10])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                IF ("Posting No. Series" = "No. Series") AND ("Posting No. Series" <> '') THEN
                  FIELDERROR("Posting No. Series",STRSUBSTNO(Text001,"Posting No. Series"));
            end;
        }
        field(23;"Copy VAT Setup to Jnl. Lines";Boolean)
        {
            Caption = 'Copy VAT Setup to Jnl. Lines';
            InitValue = true;

            trigger OnValidate()
            begin
                IF CONFIRM(
                     Text002,
                     TRUE, GenJnlBatch.FIELDCAPTION("Copy VAT Setup to Jnl. Lines"),GenJnlBatch.TABLECAPTION)
                THEN BEGIN
                  GenJnlBatch.SETRANGE("Journal Template Name",Name);
                  GenJnlBatch.MODIFYALL("Copy VAT Setup to Jnl. Lines","Copy VAT Setup to Jnl. Lines");
                  MODIFY;
                END;
            end;
        }
        field(24;"Allow VAT Difference";Boolean)
        {
            Caption = 'Allow VAT Difference';

            trigger OnValidate()
            var
                Ok: Boolean;
            begin
                IF "Allow VAT Difference" <> xRec."Allow VAT Difference" THEN
                  IF CONFIRM(
                       Text002,
                       TRUE, GenJnlBatch.FIELDCAPTION("Allow VAT Difference"),GenJnlBatch.TABLECAPTION)
                  THEN BEGIN
                    GenJnlBatch.SETRANGE("Journal Template Name",Name);
                    GenJnlBatch.MODIFYALL("Allow VAT Difference","Allow VAT Difference");
                  END;
            end;
        }
        field(25;"Cust. Receipt Report ID";Integer)
        {
            Caption = 'Cust. Receipt Report ID';
            TableRelation = Object.ID WHERE (Type=CONST(Report));
        }
        field(26;"Cust. Receipt Report Name";Text[80])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE (Object Type=CONST(Report),
                                                                           Object ID=FIELD(Cust. Receipt Report ID)));
            Caption = 'Cust. Receipt Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(27;"Vendor Receipt Report ID";Integer)
        {
            Caption = 'Vendor Receipt Report ID';
            TableRelation = Object.ID WHERE (Type=CONST(Report));
        }
        field(28;"Vendor Receipt Report Name";Text[80])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE (Object Type=CONST(Report),
                                                                           Object ID=FIELD(Vendor Receipt Report ID)));
            Caption = 'Vendor Receipt Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10000700;"Not Increase Batch Name";Boolean)
        {
            Caption = 'Not Increase Batch Name';
        }
        field(33016800;"Receipt Journal";Boolean)
        {
            Description = 'DP6.01.01';

            trigger OnValidate()
            begin
                TESTFIELD("Post Receipt Journal",FALSE); //DP6.01.01
            end;
        }
        field(33016801;"Post Receipt Journal";Boolean)
        {
            Description = 'DP6.01.01';

            trigger OnValidate()
            begin
                //DP6.01.01 START
                TESTFIELD("Receipt Journal",FALSE);
                CheckPostRcptJnlExist;
                //DP6.01.01 STOP
            end;
        }
    }

    keys
    {
        key(Key1;Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;Name,Description,Type)
        {
        }
    }

    trigger OnDelete()
    begin
        GenJnlAlloc.SETRANGE("Journal Template Name",Name);
        GenJnlAlloc.DELETEALL;
        GenJnlLine.SETRANGE("Journal Template Name",Name);
        GenJnlLine.DELETEALL(TRUE);
        GenJnlBatch.SETRANGE("Journal Template Name",Name);
        GenJnlBatch.DELETEALL;
    end;

    trigger OnInsert()
    begin
        VALIDATE("Form ID");
    end;

    var
        Text000: Label 'Only the %1 field can be filled in on recurring journals.';
        Text001: Label 'must not be %1';
        Text002: Label 'Do you want to update the %1 field on all %2es?';
        GenJnlBatch: Record "232";
        GenJnlLine: Record "81";
        GenJnlAlloc: Record "221";
        SourceCodeSetup: Record "242";
        Text33016830: Label 'Journal template = %1 already exist with post receipt journal = true';

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
 
    procedure CheckPostRcptJnlExist()
    var
        GenJnlTemplateRec: Record "80";
    begin
        //DP6.01.01 START
        IF "Post Receipt Journal" THEN BEGIN
          GenJnlTemplateRec.SETRANGE("Post Receipt Journal",TRUE);
          IF GenJnlTemplateRec.FINDFIRST THEN
            ERROR(Text33016830,GenJnlTemplateRec.Name);
        END;
        //DP6.01.01 STOP
    end;
}

