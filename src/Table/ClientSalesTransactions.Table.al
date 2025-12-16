table 33016854 "Client Sales Transactions"
{
    Caption = 'Client Sales Transactions';
    DrillDownFormID = Form33016885;
    LookupFormID = Form33016885;

    fields
    {
        field(1; "Store No."; Code[20])
        {

            trigger OnValidate()
            var
                ClientStoreRec: Record "Client Store Mapping";
            begin
                IF "Store No." <> '' THEN BEGIN
                    ClientStoreRec.RESET;
                    ClientStoreRec.SETRANGE("Client Store No.", "Store No.");
                    IF ClientStoreRec.FINDFIRST THEN
                        "Client No." := ClientStoreRec."Client No.";
                END ELSE
                    "Client No." := '';
            end;
        }
        field(2; "Pos Terminal No."; Code[20])
        {
        }
        field(3; "Line No."; Integer)
        {
        }
        field(4; "Transaction No."; Integer)
        {
        }
        field(5; Date; Date)
        {
        }
        field(6; Time; Time)
        {
        }
        field(7; Quantity; Decimal)
        {
        }
        field(8; "Net Amount (LCY)"; Decimal)
        {

            trigger OnValidate()
            begin
                "Net Amount (LCY)" := "Net Amount" * "Currency Factor";
            end;
        }
        field(10; Invoiced; Boolean)
        {
        }
        field(11; "Client Product Group"; Code[10])
        {

            trigger OnValidate()
            begin
                UpdateClientDetails;
            end;
        }
        field(12; "Client No."; Code[20])
        {
        }
        field(13; "Item Category Code"; Code[10])
        {
            TableRelation = "Item Category".Code;
        }
        field(14; "Product Group"; Code[10])
        {
            TableRelation = "Product Group".Code WHERE(Item Category Code=FIELD(Item Category Code));
        }
        field(15; "Net Amount"; Decimal)
        {

            trigger OnValidate()
            begin
                "Net Amount (LCY)" := "Net Amount" * "Currency Factor";
            end;
        }
        field(16; "Currency Code"; Code[10])
        {
        }
        field(17; "Currency Factor"; Decimal)
        {

            trigger OnValidate()
            begin
                "Net Amount (LCY)" := "Net Amount" * "Currency Factor";
            end;
        }
    }

    keys
    {
        key(Key1; "Store No.", "Pos Terminal No.", "Transaction No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Store No.", Date)
        {
        }
        key(Key3; "Client No.", "Store No.", "Client Product Group")
        {
        }
        key(Key4; "Client No.", "Item Category Code", "Product Group", Date)
        {
            SumIndexFields = "Net Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    procedure UpdateClientDetails()
    var
        ClientProductRec: Record "Client Product Group";
        ClientStoreRec: Record "Client Store Mapping";
    begin
        IF ("Client No." = '') AND ("Store No." <> '') THEN BEGIN
            ClientStoreRec.RESET;
            ClientStoreRec.SETRANGE("Client Store No.", "Store No.");
            IF ClientStoreRec.FINDFIRST THEN
                "Client No." := ClientStoreRec."Client No.";
        END;

        IF ("Client No." <> '') AND ("Client Product Group" <> '') THEN BEGIN
            ClientProductRec.RESET;
            ClientProductRec.SETRANGE("Client No.", "Client No.");
            ClientProductRec.SETRANGE("Client Product Group", "Client Product Group");
            IF ClientProductRec.FINDFIRST THEN BEGIN
                "Item Category Code" := ClientProductRec."Item Category Code";
                "Product Group" := ClientProductRec."Product Group";
            END;
        END;
    end;
}

