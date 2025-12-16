table 33016823 "Completion Code"
{
    Caption = 'Completion Code';
    LookupFormID = Form33016827;

    fields
    {
        field(1; "Completion Code"; Code[10])
        {
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
        }
        field(3; Complete; Boolean)
        {

            trigger OnValidate()
            var
                CompletionCodeRec: Record "Completion Code";
            begin
                IF Complete THEN BEGIN
                    CompletionCodeRec.RESET;
                    CompletionCodeRec.SETFILTER("Completion Code", '<>%1', "Completion Code");
                    CompletionCodeRec.SETRANGE(Complete, TRUE);
                    IF CompletionCodeRec.FINDFIRST THEN
                        ERROR(Text001, CompletionCodeRec."Completion Code");
                END;
            end;
        }
    }

    keys
    {
        key(Key1; "Completion Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'Complete Status is already linked to Completion Code %1';
}

