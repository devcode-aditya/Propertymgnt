table 33016811 "Facility Type"
{
    Caption = 'Facility Type';
    LookupFormID = Form33016813;

    fields
    {
        field(1; "Code"; Code[20])
        {
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
        }
        field(3; Utility; Boolean)
        {

            trigger OnValidate()
            begin
                CheckFacilityAttached;
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Utility)
        {
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'Facility %1 exists with Utility %2';

    procedure CheckFacilityAttached()
    var
        Facility: Record Facility;
    begin
        Facility.SETRANGE("Facility Type", Code);
        IF Facility.FINDFIRST THEN
            ERROR(Text001, Facility."No.", Code);
    end;
}

