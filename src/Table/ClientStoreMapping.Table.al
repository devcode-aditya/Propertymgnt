table 33016853 "Client Store Mapping"
{
    Caption = 'Client - Store Setup';
    LookupFormID = Form33016884;

    fields
    {
        field(1; "Client No."; Code[20])
        {
            NotBlank = true;
            TableRelation = Customer.No.;

            trigger OnValidate()
            begin
                IF "Client No." <> xRec."Client No." THEN
                  "Client Name" := '';
                IF Customer.GET("Client No.") THEN
                  "Client Name" := Customer.Name;
            end;
        }
        field(2;"Client Name";Text[50])
        {
            Editable = false;
        }
        field(3;"Client Store No.";Code[20])
        {
            NotBlank = true;
        }
        field(4;"Client Store Description";Text[50])
        {
        }
    }

    keys
    {
        key(Key1;"Client No.","Client Store No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Customer: Record Customer;
        Text001: Label 'Client Product Group %1 must be blank.';
}

