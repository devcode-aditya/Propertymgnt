table 33016850 "SMS Integration Setup"
{
    Caption = 'SMS Integration Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
        }
        field(2; "SMS Send Type"; Text[100])
        {
            Caption = 'SMS Send Type';
        }
        field(3; "SMS HTTP URL"; Text[100])
        {
            Caption = 'SMS HTTP URL';
        }
        field(4; "SMS Email Server"; Text[100])
        {
            Caption = 'SMS Email Server';
        }
        field(5; "SMS User"; Text[30])
        {
            Caption = 'SMS User';
        }
        field(6; "SMS Password"; Text[30])
        {
            Caption = 'SMS Password';
        }
        field(7; "SMS Sender Phone"; Text[30])
        {
            Caption = 'SMS Sender Phone';
        }
        field(8; "Sent SMS File Path"; Text[250])
        {
        }
        field(9; "Response File Path"; Text[250])
        {
        }
        field(10; "SOAP Action"; Text[250])
        {
        }
        field(11; "Header Text"; Text[60])
        {
            Caption = 'Header Text';
        }
        field(12; "Footnote Text"; Text[60])
        {
            Caption = 'Footnote Text';
        }
        field(13; "Mobile No. Digits Allowed"; Integer)
        {
        }
        field(14; "Send SMS for Work Order"; Boolean)
        {
        }
        field(15; "Send SMS for Call Register"; Boolean)
        {
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

