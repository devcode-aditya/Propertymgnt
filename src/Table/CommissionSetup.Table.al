table 33016828 "Commission Setup"
{
    Caption = 'Commission Setup';

    fields
    {
        field(1; "Commission Agent"; Code[10])
        {
            TableRelation = "Sales Representative";
        }
        field(2; "Target Amount Min"; Decimal)
        {
        }
        field(3; "Target Amount Max"; Decimal)
        {
        }
        field(4; "Turnover Amount"; Decimal)
        {
            CalcFormula = Sum ("Agreement Line"."Original Amount" WHERE (Sales Representative=FIELD(Commission Agent),
                                                                        Signature Date=FIELD(Date Filter)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(5;"Commission Type";Option)
        {
            OptionCaption = '%age,Amount';
            OptionMembers = "%age",Amount;
        }
        field(6;Commission;Decimal)
        {
        }
        field(7;"Period Start Date";Date)
        {
        }
        field(8;"Period End Date";Date)
        {
        }
        field(9;"Target Achieved";Boolean)
        {
            Editable = false;
        }
        field(10;"Date Filter";Date)
        {
            FieldClass = FlowFilter;
        }
        field(11;"Premise No.";Code[20])
        {
            TableRelation = Premise.No.;
        }
    }

    keys
    {
        key(Key1;"Commission Agent","Period Start Date","Period End Date","Target Amount Min","Target Amount Max","Commission Type",Commission)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

