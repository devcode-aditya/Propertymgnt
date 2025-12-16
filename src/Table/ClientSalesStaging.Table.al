table 33016858 "Client Sales Staging"
{
    Caption = 'Client Sales Staging';

    fields
    {
        field(1; "Store No."; Code[20])
        {
        }
        field(2; "Pos Terminal No."; Code[20])
        {
        }
        field(3; "Line No."; Integer)
        {
        }
        field(4; "Transaction No."; Integer)
        {
        }
        field(5; Date; Date)
        {
        }
        field(6; Time; Time)
        {
        }
        field(7; Quantity; Decimal)
        {
        }
        field(8; "Net Amount (LCY)"; Decimal)
        {

            trigger OnValidate()
            begin
                "Net Amount (LCY)" := "Net Amount" * "Currency Factor";
            end;
        }
        field(10; Invoiced; Boolean)
        {
            Enabled = false;
        }
        field(11; "Client Product Group"; Code[10])
        {
        }
        field(12; "Entry No. in Register"; Integer)
        {
        }
        field(13; Status; Option)
        {
            OptionCaption = ' ,Imported to Master,Error';
            OptionMembers = " ","Imported to Master",Error;
        }
        field(14; "Record Number"; Integer)
        {
        }
        field(15; "Entry No."; Integer)
        {
            NotBlank = true;
        }
        field(16; "Error String"; Text[100])
        {
        }
        field(17; "Currency Code"; Code[10])
        {
        }
        field(18; "Net Amount"; Decimal)
        {

            trigger OnValidate()
            begin
                "Net Amount (LCY)" := "Net Amount" * "Currency Factor";
            end;
        }
        field(19; "Currency Factor"; Decimal)
        {

            trigger OnValidate()
            begin
                "Net Amount (LCY)" := "Net Amount" * "Currency Factor";
            end;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
        }
        key(Key2; "Store No.", "Pos Terminal No.", "Transaction No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key3; "Store No.", Date)
        {
        }
    }

    fieldgroups
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
}

