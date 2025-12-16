table 33016833 "Premise Events"
{
    Caption = 'Premise Events';
    DrillDownFormID = Form33016869;
    LookupFormID = Form33016818;

    fields
    {
        field(1; "Premises Code"; Code[20])
        {
            TableRelation = Premise;
        }
        field(2; "Event Code"; Code[20])
        {
            TableRelation = "Event Detail";
        }
        field(3; "Premise Name"; Text[50])
        {
            CalcFormula = Lookup (Premise.Name WHERE (No.=FIELD(Premises Code)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(4;"Event Name";Text[50])
        {
            CalcFormula = Lookup("Event Detail".Name WHERE (No.=FIELD(Event Code)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(5;"No. of Active Events";Integer)
        {
            BlankZero = true;
            CalcFormula = Count("Event Detail" WHERE (Status=FILTER(Cancelled),
                                                      No.=FIELD(Event Code)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(6;"No. of Closed Events";Integer)
        {
            BlankZero = true;
            CalcFormula = Count("Event Detail" WHERE (Status=FILTER(Closed),
                                                      No.=FIELD(Event Code)));
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1;"Premises Code","Event Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        PremiseEventRec: Record "Premise Events";
    begin
    end;

    var
        Text002: Label 'Next date will be before today! Change next date to current date?';
        Text001: Label 'New recurring event created for %1';
}

