table 33016870 "Facility Sub Group"
{
    DrillDownFormID = Form33016919;
    LookupFormID = Form33016919;

    fields
    {
        field(1; "Facility Group"; Code[20])
        {
            TableRelation = "Facility Group";
        }
        field(2; "Facility Sub Group"; Code[20])
        {
        }
        field(3; Description; Text[30])
        {
        }
    }

    keys
    {
        key(Key1; "Facility Group", "Facility Sub Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

