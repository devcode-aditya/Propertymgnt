table 33016856 "Integration Setup"
{
    Caption = 'Integration Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
        }
        field(2; "FTP Login (Import)"; Text[30])
        {
        }
        field(3; "FTP Password (Import)"; Text[30])
        {
        }
        field(4; "FTP Host (Import)"; Code[50])
        {
        }
        field(11; "FTP Location (Sales Trans.)"; Text[70])
        {
        }
        field(12; "Local Location (Sales Trans.)"; Text[70])
        {
        }
        field(13; "Archive Location (Sales Trans)"; Text[70])
        {
        }
        field(14; "Duplicate Loc. (Sales Trans.)"; Text[70])
        {
        }
        field(15; "File Suffix (Sales Trans.)"; Text[20])
        {
        }
        field(16; "FTP Archive (Sales Trans.)"; Text[70])
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

