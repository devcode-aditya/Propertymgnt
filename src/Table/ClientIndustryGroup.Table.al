table 33016868 "Client Industry Group"
{
    Caption = 'Client Industry Group';
    DrillDownFormID = Form33016917;
    LookupFormID = Form33016917;

    fields
    {
        field(1; "Client No."; Code[20])
        {
            TableRelation = Customer;
        }
        field(2; "Industry Group"; Code[10])
        {
            NotBlank = true;
            TableRelation = "Industry Group";
        }
        field(3; Description; Text[30])
        {
            CalcFormula = Lookup ("Industry Group".Description WHERE (Code = FIELD (Industry Group)));
            FieldClass = FlowField;
        }
        field(4; "Contact No."; Code[20])
        {
            TableRelation = Contact;
        }
    }

    keys
    {
        key(Key1; "Client No.", "Industry Group")
        {
            Clustered = true;
        }
        key(Key2; "Contact No.")
        {
        }
    }

    fieldgroups
    {
    }
}

