table 33016871 "Apply Agrmt. Line Entry"
{
    DrillDownFormID = Form33016921;
    LookupFormID = Form33016921;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            Editable = false;
            TableRelation = "Gen. Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            Editable = false;
            TableRelation = "Gen. Journal Batch".Name WHERE (Journal Template Name=FIELD(Journal Template Name));
        }
        field(3; "Journal Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(5; "Ref. Document Type"; Option)
        {
            Editable = false;
            OptionCaption = 'Lease,Sale,Work Order';
            OptionMembers = Lease,Sale,"Work Order";
        }
        field(6; "Ref. Document No."; Code[20])
        {
            Editable = false;
        }
        field(7; "Ref. Document Line No."; Integer)
        {
            BlankZero = true;
            Editable = false;
            TableRelation = "Agreement Line"."Line No." WHERE (Agreement No.=FIELD(Ref. Document No.),
                                                               Agreement Type=FIELD(Ref. Document Type));

            trigger OnValidate()
            var
                AgrmtLine: Record "Agreement Line";
            begin
            end;
        }
        field(8;"Payment Schedule Line No.";Integer)
        {
            Editable = false;
        }
        field(9;"Invoice Due Amt.";Decimal)
        {
            Editable = false;

            trigger OnValidate()
            var
                AgreementLineRec: Record "Agreement Line";
            begin
            end;
        }
        field(10;"Element Type";Code[20])
        {
            Editable = false;
        }
        field(11;Description;Text[50])
        {
            Editable = false;
        }
        field(12;"Line No.";Integer)
        {
            Editable = false;
        }
        field(13;"Amount to Apply";Decimal)
        {

            trigger OnValidate()
            var
                AgrmtApplyLines: Record "Apply Agrmt. Line Entry";
                TotalAppliedAmt: Decimal;
            begin
                IF "Remaining Amt." < "Amount to Apply" THEN
                  ERROR(Text000,"Remaining Amt.");

                AgrmtApplyLines.RESET;
                AgrmtApplyLines.SETRANGE("Ref. Document Type","Ref. Document Type");
                AgrmtApplyLines.SETRANGE("Ref. Document No.","Ref. Document No.");
                AgrmtApplyLines.SETRANGE("Ref. Document Line No.","Ref. Document Line No.");
                AgrmtApplyLines.SETRANGE("Payment Schedule Line No.","Payment Schedule Line No.");
                AgrmtApplyLines.SETFILTER("Line No.",'<>%1',"Line No.");
                IF AgrmtApplyLines.FINDSET THEN BEGIN
                  REPEAT
                    TotalAppliedAmt += AgrmtApplyLines."Amount to Apply";
                  UNTIL AgrmtApplyLines.NEXT = 0;
                END;

                IF TotalAppliedAmt + "Amount to Apply" > "Remaining Amt." THEN
                  ERROR(Text000,"Remaining Amt." - TotalAppliedAmt);
            end;
        }
        field(14;"Applied Amount";Decimal)
        {
            Editable = false;
        }
        field(15;"Remaining Amt.";Decimal)
        {
            Editable = false;
        }
        field(16;"Due Date";Date)
        {
        }
    }

    keys
    {
        key(Key1;"Journal Template Name","Journal Batch Name","Journal Line No.","Ref. Document Type","Ref. Document No.","Ref. Document Line No.","Payment Schedule Line No.","Line No.")
        {
            Clustered = true;
        }
        key(Key2;"Ref. Document Type","Ref. Document No.","Ref. Document Line No.","Payment Schedule Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label 'Amount must be less than %1';
}

