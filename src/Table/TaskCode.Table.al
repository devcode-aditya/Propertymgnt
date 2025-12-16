table 33016834 "Task Code"
{
    // LG00.02 20032014 Added Field "Task Classification"

    Caption = 'Task Code';
    LookupFormID = Form33016828;

    fields
    {
        field(1; "Code"; Code[20])
        {
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
        }
        field(3; "Task Cost"; Decimal)
        {
            MinValue = 0;
        }
        field(4; "Task Price"; Decimal)
        {
            MinValue = 0;
        }
        field(5; "Revenue Account"; Code[20])
        {
            TableRelation = "G/L Account".No.;
        }
        field(6;"Expense Account";Code[20])
        {
            TableRelation = "G/L Account".No.;
        }
        field(7;"Unit of Measure";Code[10])
        {
            TableRelation = "Unit of Measure".Code;
        }
        field(8;"Vendor No.";Code[20])
        {
            TableRelation = Vendor.No.;
        }
        field(9;Quantity;Decimal)
        {
            MinValue = 0;
        }
        field(10;"Task Type";Option)
        {
            OptionCaption = ' ,Labour,Material';
            OptionMembers = " ",Labour,Material;
        }
        field(11;"Task Classification";Option)
        {
            Description = 'LG00.02';
            OptionCaption = ' ,Chargable,Non-Chargable,Projects';
            OptionMembers = " ",Chargable,"Non-Chargable",Projects;
        }
    }

    keys
    {
        key(Key1;"Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

