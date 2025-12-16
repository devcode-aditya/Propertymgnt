table 33016832 "Premises Resource Link"
{
    Caption = 'Premises Resource Link';

    fields
    {
        field(1; "Premsie Code"; Code[20])
        {
            TableRelation = Premise;
        }
        field(2; "Resource No."; Code[20])
        {
            TableRelation = Resource;

            trigger OnValidate()
            begin
                CALCFIELDS("Resource Name");
            end;
        }
        field(3; "Resource Name"; Text[30])
        {
            CalcFormula = Lookup (Resource.Name WHERE (No.=FIELD(Resource No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(4;Preferred;Boolean)
        {
        }
        field(5;"Resource Group No.";Code[20])
        {
            CalcFormula = Lookup(Resource."Resource Group No." WHERE (No.=FIELD(Resource No.)));
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1;"Premsie Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

