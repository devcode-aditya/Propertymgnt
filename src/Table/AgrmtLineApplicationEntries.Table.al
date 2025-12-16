table 33016872 "Agrmt Line Application Entries"
{
    // LG00.02 20032014 Modify Field "Entry Type" added option "Refund"

    Caption = 'Agrmt Line Application Entries';
    DrillDownFormID = Form33016922;
    LookupFormID = Form33016922;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name WHERE (Journal Template Name=FIELD(Journal Template Name));
        }
        field(3; "Journal Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(5; "Ref. Document Type"; Option)
        {
            OptionCaption = 'Lease,Sale,Work Order';
            OptionMembers = Lease,Sale,"Work Order";
        }
        field(6; "Ref. Document No."; Code[20])
        {
        }
        field(7; "Ref. Document Line No."; Integer)
        {
            BlankZero = true;
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
        }
        field(9;"Invoice Due Amt.";Decimal)
        {

            trigger OnValidate()
            var
                AgreementLineRec: Record "Agreement Line";
            begin
            end;
        }
        field(10;"Element Type";Code[20])
        {
        }
        field(11;Description;Text[50])
        {
        }
        field(12;"Entry No.";Integer)
        {
        }
        field(13;"Applied Amount";Decimal)
        {
        }
        field(14;"Entry Type";Option)
        {
            Description = 'LG00.02';
            OptionCaption = 'Approved,Processed,Posted,Refund';
            OptionMembers = Approved,Processed,Posted,Refund;
        }
        field(15;"Due Date";Date)
        {
        }
    }

    keys
    {
        key(Key1;"Entry No.")
        {
        }
        key(Key2;"Journal Template Name","Journal Batch Name","Journal Line No.","Ref. Document Type","Ref. Document No.","Ref. Document Line No.","Payment Schedule Line No.","Entry No.")
        {
            Clustered = true;
        }
        key(Key3;"Ref. Document Type","Ref. Document No.","Ref. Document Line No.","Payment Schedule Line No.","Element Type","Entry Type")
        {
            SumIndexFields = "Applied Amount";
        }
    }

    fieldgroups
    {
    }
}

