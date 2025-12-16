table 33016866 "Client Mailing Group"
{
    Caption = 'Client Mailing Group';
    DrillDownFormID = Form33016915;
    LookupFormID = Form33016915;

    fields
    {
        field(1; "Client No."; Code[20])
        {
            TableRelation = Customer;
        }
        field(2; "Mailing Group"; Code[10])
        {
            NotBlank = true;
            TableRelation = "Mailing Group";
        }
        field(3; Description; Text[30])
        {
            CalcFormula = Lookup ("Mailing Group".Description WHERE (Code = FIELD (Mailing Group)));
            FieldClass = FlowField;
            NotBlank = true;
        }
        field(4; "Contact No."; Code[20])
        {
            TableRelation = Contact;
        }
    }

    keys
    {
        key(Key1; "Client No.", "Mailing Group")
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

