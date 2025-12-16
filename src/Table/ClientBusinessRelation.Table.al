table 33016867 "Client Business Relation"
{
    Caption = 'Client Business Relation';
    DrillDownFormID = Form33016916;
    LookupFormID = Form33016916;

    fields
    {
        field(1; "Client No."; Code[20])
        {
            TableRelation = Customer;
        }
        field(2; "Business Group"; Code[10])
        {
            NotBlank = true;
            TableRelation = "Business Relation";
        }
        field(3; Description; Text[30])
        {
            CalcFormula = Lookup ("Business Relation".Description WHERE (Code = FIELD (Business Group)));
            FieldClass = FlowField;
        }
        field(4; "Contact No."; Code[20])
        {
            TableRelation = Contact;
        }
    }

    keys
    {
        key(Key1; "Client No.", "Business Group")
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

