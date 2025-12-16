table 33016830 "Revenue Sharing Slab"
{
    Caption = 'Revenue Sharing Slab';

    fields
    {
        field(1; "Client No."; Code[20])
        {
            TableRelation = Customer.No.;

            trigger OnValidate()
            begin
                SetClientProductGroup;
            end;
        }
        field(2; "Item Category Code"; Code[10])
        {
            TableRelation = "Item Category".Code;

            trigger OnValidate()
            begin
                IF "Item Category Code" <> xRec."Item Category Code" THEN
                    "Product Group" := '';

                SetClientProductGroup;
            end;
        }
        field(3; "Start Date"; Date)
        {
        }
        field(4; "Min. Sale"; Decimal)
        {
        }
        field(5; "Max. Sale"; Decimal)
        {
        }
        field(6; "Slab Type"; Option)
        {
            OptionCaption = '%age,Amount';
            OptionMembers = "%age",Amount;
        }
        field(7; Slab; Decimal)
        {
        }
        field(9; "Product Group"; Code[10])
        {
            TableRelation = "Product Group".Code WHERE(Item Category Code=FIELD(Item Category Code));

            trigger OnValidate()
            begin
                SetClientProductGroup;
            end;
        }
        field(10; "End Date"; Date)
        {
        }
        field(11; "Client Product Group"; Code[20])
        {

            trigger OnLookup()
            var
                ClientProductRec: Record "Client Product Group";
                ClientProductFrm: Form "33016887";
            begin
                ClientProductRec.RESET;
                CLEAR(ClientProductFrm);
                ClientProductRec.SETRANGE("Client No.", "Client No.");
                ClientProductRec.SETRANGE("Item Category Code", "Item Category Code");
                ClientProductRec.SETRANGE("Product Group", "Product Group");
                ClientProductFrm.SETTABLEVIEW(ClientProductRec);
                ClientProductFrm.SETRECORD(ClientProductRec);
                ClientProductFrm.LOOKUPMODE(TRUE);
                IF ClientProductFrm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                    ClientProductFrm.GETRECORD(ClientProductRec);
                    VALIDATE("Client Product Group", ClientProductRec."Client Product Group");
                END;
            end;

            trigger OnValidate()
            begin
                SetClientProductGroup;
            end;
        }
    }

    keys
    {
        key(Key1; "Client No.", "Item Category Code", "Product Group", "Start Date", "End Date", "Min. Sale", "Max. Sale")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetClientProductGroup()
    var
        ClientProductRec: Record "Client Product Group";
    begin
        IF ClientProductRec.GET("Client No.", "Item Category Code", "Product Group") THEN
            "Client Product Group" := ClientProductRec."Client Product Group"
        ELSE
            "Client Product Group" := '';
    end;
}

