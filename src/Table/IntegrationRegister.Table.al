table 33016857 "Integration Register"
{
    Caption = 'Integration Register';

    fields
    {
        field(1; "S.No"; Integer)
        {
        }
        field(2; "File Name"; Text[245])
        {
        }
        field(3; Status; Option)
        {
            OptionCaption = ' ,Imported to Staging Table,Error while Importing to Staging,Partially Imported to Master,Imported to Master,Exported';
            OptionMembers = " ","Imported to Staging Table","Error while Importing to Staging","Partially Imported to Master","Imported to Master",Exported;
        }
        field(4; Date; Date)
        {
        }
        field(5; Time; Time)
        {
        }
        field(6; "Error String"; Text[250])
        {
        }
        field(7; "File Type"; Option)
        {
            OptionCaption = ' ,Sales';
            OptionMembers = " ",Sales;
        }
        field(8; Type; Option)
        {
            OptionCaption = ' ,Export,Import';
            OptionMembers = " ",Export,Import;
        }
    }

    keys
    {
        key(Key1; "S.No")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

