table 33016808 "Premise Assets"
{
    Caption = 'Premise Assets';
    LookupFormID = Form33016808;

    fields
    {
        field(1; "Premise Code"; Code[20])
        {
            TableRelation = Premise.No.;
        }
        field(2;Type;Option)
        {
            OptionCaption = ' ,Fixed Asset';
            OptionMembers = " ","Fixed Asset";

            trigger OnValidate()
            begin
                IF Type <> xRec.Type THEN BEGIN
                  "No." := '';
                  Description := '';
                  "FA Class Code" := '';
                  "FA Sub Class Code" := '';
                  "FA Location Code" := '';
                END;
            end;
        }
        field(3;"No.";Code[20])
        {
            TableRelation = IF (Type=CONST(Fixed Asset)) "Fixed Asset";

            trigger OnValidate()
            var
                FixedAssetRec: Record "Fixed Asset";
            begin
                CASE Type OF
                  Type::"Fixed Asset":
                    BEGIN
                      FixedAssetRec.GET("No.");
                      Description := FixedAssetRec.Description;
                      "FA Class Code" := FixedAssetRec."FA Class Code";
                      "FA Sub Class Code" := FixedAssetRec."FA Subclass Code";
                      "FA Location Code" := FixedAssetRec."FA Location Code";
                    END;
                  Type::" ":
                    BEGIN
                      "No." := '';
                      Description := '';
                      "FA Class Code" := '';
                      "FA Sub Class Code" := '';
                      "FA Location Code" := '';
                    END;
                END;
            end;
        }
        field(4;Description;Text[50])
        {
        }
        field(5;"FA Class Code";Code[20])
        {
        }
        field(6;"FA Sub Class Code";Code[20])
        {
        }
        field(7;"FA Location Code";Code[20])
        {
        }
        field(8;Quantity;Decimal)
        {
        }
    }

    keys
    {
        key(Key1;"Premise Code",Type,"No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        IF "No." = '' THEN
          ERROR(Text33016827,"Premise Code");
    end;

    var
        Text33016827: Label 'No. must not be blank for Premise %1';
}

