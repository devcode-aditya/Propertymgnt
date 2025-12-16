table 33016820 "Premise Insurance Schedule"
{
    Caption = 'Premise Insurance Schedule';

    fields
    {
        field(1; "Insurance Code"; Code[20])
        {
            TableRelation = "Premise Insurance"."Insurance Code";
        }
        field(2; "Starting Date"; Date)
        {
        }
        field(3; "Valid Upto"; Date)
        {
        }
        field(4; "Premium Amount"; Decimal)
        {
        }
        field(5; "Insurance Authority"; Code[20])
        {
            TableRelation = Vendor.No.;

            trigger OnValidate()
            var
                InsuranceRec: Record "Premise Insurance";
            begin
                IF InsuranceRec.GET("Insurance Code") THEN BEGIN
                    IF "Insurance Authority" <> InsuranceRec."Insurance Authority" THEN
                        ERROR(Text001, InsuranceRec."Insurance Authority", "Insurance Authority");
                END ELSE
                    "Insurance Authority" := '';
            end;
        }
        field(6; "Premise No."; Code[20])
        {
            TableRelation = Premise.No.;

            trigger OnValidate()
            var
                InsuranceRec: Record "Premise Insurance";
            begin
                IF InsuranceRec.GET("Insurance Code") THEN BEGIN
                    IF "Premise No." <> InsuranceRec."Premise No." THEN
                        ERROR(Text001, InsuranceRec."Premise No.", "Premise No.");
                END ELSE
                    "Premise No." := '';
            end;
        }
    }

    keys
    {
        key(Key1; "Insurance Code", "Starting Date", "Valid Upto")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        UpdateInsuranceDetails;
    end;

    var
        Text001: Label 'Premise No. %1 specified on Premise Insurance Card is different than Premise No. %2 entered in Insurance Schedule.';
        Text002: Label 'Insurance Authority %1 specified on Premise Insurance Card is different than Insurance Authority %2 entered in Insurance Schedule.';

    procedure UpdateInsuranceDetails()
    var
        InsuranceRec: Record "Premise Insurance";
    begin
        IF InsuranceRec.GET("Insurance Code") THEN BEGIN
            "Premise No." := InsuranceRec."Premise No.";
            "Insurance Authority" := InsuranceRec."Insurance Authority";
        END ELSE BEGIN
            "Premise No." := '';
            "Insurance Authority" := '';
        END;
    end;
}

