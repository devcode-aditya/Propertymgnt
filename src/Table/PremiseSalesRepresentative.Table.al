table 33016860 "Premise Sales Representative"
{
    Caption = 'Premise Sales Representative';

    fields
    {
        field(1; "Premise No."; Code[20])
        {
            NotBlank = true;
            TableRelation = Premise.No.;

            trigger OnValidate()
            var
                PremiseRec: Record Premise;
            begin
                IF PremiseRec.GET("Premise No.") THEN
                  "Premise Name" := PremiseRec.Name
                ELSE
                  "Premise Name" := '';
            end;
        }
        field(2;"Sales Representative";Code[20])
        {
            NotBlank = true;
            TableRelation = "Sales Representative".No.;

            trigger OnValidate()
            var
                CommissionAgent: Record "Sales Representative";
            begin
                IF CommissionAgent.GET("Sales Representative") THEN
                  "Sales Representative Name" := CommissionAgent.Name
                ELSE
                  "Sales Representative Name" := '';
            end;
        }
        field(3;"Premise Name";Text[50])
        {

            trigger OnValidate()
            begin
                IF "Premise No." = '' THEN
                  "Premise Name" := '';
            end;
        }
        field(4;"Sales Representative Name";Text[50])
        {

            trigger OnValidate()
            begin
                IF "Sales Representative" = '' THEN
                  "Sales Representative Name" := '';
            end;
        }
    }

    keys
    {
        key(Key1;"Premise No.","Sales Representative")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

