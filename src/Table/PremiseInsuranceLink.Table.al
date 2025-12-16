table 33016847 "Premise Insurance Link"
{
    DrillDownFormID = Form33016872;
    LookupFormID = Form33016872;

    fields
    {
        field(1; "Premise Code"; Code[20])
        {
            TableRelation = Premise.No.;

            trigger OnValidate()
            var
                PremiseRec: Record Premise;
            begin
                IF PremiseRec.GET("Premise Code") THEN
                  "Premise Description" := PremiseRec.Name
                ELSE
                  "Premise Description" := '';
            end;
        }
        field(2;"Premise Description";Text[50])
        {
        }
        field(3;"Insurance Code";Code[20])
        {
            TableRelation = "Premise Insurance"."Insurance Code";

            trigger OnValidate()
            var
                PremiseInsurance: Record "Premise Insurance";
            begin
                IF PremiseInsurance.GET("Insurance Code") THEN
                  "Insurance Description" := PremiseInsurance."Insurance Description"
                ELSE
                  "Insurance Description" := '';
            end;
        }
        field(4;"Insurance Description";Text[50])
        {
        }
    }

    keys
    {
        key(Key1;"Premise Code","Insurance Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

