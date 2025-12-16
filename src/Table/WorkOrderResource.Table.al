table 33016839 "Work Order Resource"
{
    Caption = 'Work Order Resource';

    fields
    {
        field(1; "Work Order No."; Code[20])
        {
            TableRelation = "Work Order Header".No.;
        }
        field(2;"Resource No.";Code[20])
        {
            TableRelation = Resource.No.;

            trigger OnValidate()
            var
                ResourceRec: Record Resource;
            begin
                IF "Resource No." <> '' THEN BEGIN
                  ResourceRec.GET("Resource No.");
                  "Resource Name" := ResourceRec.Name;
                END ELSE
                  "Resource Name" := '';
            end;
        }
        field(3;"Resource Name";Text[50])
        {
        }
    }

    keys
    {
        key(Key1;"Work Order No.","Resource No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

