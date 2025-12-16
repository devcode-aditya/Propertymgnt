table 33016855 "Client Product Group"
{
    Caption = 'Client Product Group';
    DrillDownFormID = Form33016887;
    LookupFormID = Form33016887;

    fields
    {
        field(1; "Client No."; Code[20])
        {
            NotBlank = true;
            TableRelation = Customer.No.;

            trigger OnValidate()
            var
                ClientRec: Record Customer;
            begin
                IF ClientRec.GET("Client No.") THEN
                    "Client Name" := ClientRec.Name
                ELSE
                    "Client Name" := '';
            end;
        }
        field(2; "Item Category Code"; Code[20])
        {
            TableRelation = "Item Category".Code;

            trigger OnValidate()
            var
                ItemCategoryRec: Record "Item Category";
            begin
                IF ItemCategoryRec.GET("Item Category Code") THEN
                    "Item Category Description" := ItemCategoryRec.Description
                ELSE
                    "Item Category Description" := '';
                ValidateClientProductGroup;
            end;
        }
        field(3; "Product Group"; Code[20])
        {
            TableRelation = "Product Group".Code WHERE(Item Category Code=FIELD(Item Category Code));

            trigger OnValidate()
            var
                ProductGroupRec: Record "Product Group";
            begin
                IF ProductGroupRec.GET("Item Category Code", "Product Group") THEN
                    "Product Group Description" := ProductGroupRec.Description
                ELSE
                    "Product Group Description" := '';
                ValidateClientProductGroup;
            end;
        }
        field(4; "Client Name"; Text[50])
        {
        }
        field(5; "Item Category Description"; Text[50])
        {
            Editable = false;
        }
        field(6; "Product Group Description"; Text[50])
        {
            Editable = false;
        }
        field(7; "Client Product Group"; Code[20])
        {

            trigger OnValidate()
            var
                ClientProductGroupRec: Record "Client Product Group";
            begin
                ValidateClientProductGroup;

                IF "Client Product Group" <> '' THEN BEGIN
                    ClientProductGroupRec.RESET;
                    ClientProductGroupRec.SETRANGE("Client No.", "Client No.");
                    ClientProductGroupRec.SETRANGE("Client Product Group", "Client Product Group");
                    IF ClientProductGroupRec.FINDFIRST THEN
                        REPEAT
                            IF (ClientProductGroupRec."Item Category Code" <> "Item Category Code") OR
                               (ClientProductGroupRec."Product Group" <> "Product Group") THEN
                                ERROR(Text002, ClientProductGroupRec."Client Product Group", ClientProductGroupRec."Client No.",
                                ClientProductGroupRec."Item Category Code", ClientProductGroupRec."Product Group");
                        UNTIL ClientProductGroupRec.NEXT = 0;
                END;
            end;
        }
    }

    keys
    {
        key(Key1; "Client No.", "Item Category Code", "Product Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'Both Item Category Code and Product Group must not be blank.';
        Text002: Label 'Client Product Group : %1 of Client  : %2 is already linked with Item Category Code : %3 & Product Group : %4';

    procedure ValidateClientProductGroup()
    begin
        IF ("Item Category Code" = '') AND ("Product Group" = '') THEN BEGIN
            "Client Product Group" := '';
            MESSAGE(Text001);
        END;
    end;
}

