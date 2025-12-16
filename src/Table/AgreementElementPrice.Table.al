table 33016813 "Agreement Element Price"
{
    Caption = 'Agreement Element Price';

    fields
    {
        field(1; "Element Type"; Code[20])
        {
            TableRelation = "Agreement Element".Code;
        }
        field(2; "Price Type"; Option)
        {
            OptionCaption = 'All,Client';
            OptionMembers = All,Client;
        }
        field(3; "Price Code"; Code[20])
        {
            // TableRelation = IF ("Price Type" = FILTER(Client)) Customer WHERE(Client Type=FILTER(Client|Tenant)); // Aditya 
        }
        field(4; "Currency Code"; Code[10])
        {
            TableRelation = Currency;
        }
        field(5; "Starting Date"; Date)
        {
        }
        field(6; "Ending Date"; Date)
        {
        }
        field(7; "Unit Price"; Decimal)
        {
        }
        field(8; "Unit of Measure Code"; Code[10])
        {
            TableRelation = "Unit of Measure";
        }
    }

    keys
    {
        key(Key1; "Element Type", "Price Type", "Price Code", "Starting Date", "Ending Date", "Currency Code", "Unit of Measure Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

