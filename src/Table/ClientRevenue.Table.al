table 33016829 "Client Revenue"
{
    Caption = 'Client Revenue';

    fields
    {
        field(1; "Client No."; Code[20])
        {

            trigger OnLookup()
            var
                ClientRec: Record Customer;
                ClientFrm: Form "33016840";
            begin
                CLEAR(ClientFrm);
                ClientRec.RESET;
                ClientRec.SETFILTER("Client Type", '%1|%2', ClientRec."Client Type"::Client, ClientRec."Client Type"::Tenant);
                ClientFrm.SETTABLEVIEW(ClientRec);
                ClientFrm.LOOKUPMODE(TRUE);
                ClientFrm.SETRECORD(ClientRec);
                IF ClientFrm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                    ClientFrm.GETRECORD(ClientRec);
                    VALIDATE("Client No.", ClientRec."No.");
                END;
            end;

            trigger OnValidate()
            var
                ClientRec: Record Customer;
            begin
                IF "Client No." <> xRec."Client No." THEN BEGIN
                    "Client Name" := '';
                    "Client Product Group" := '';
                END;

                IF "Client No." <> '' THEN BEGIN
                    ClientRec.GET("Client No.");
                    IF NOT ((ClientRec."Client Type" = ClientRec."Client Type"::Client) OR
                      (ClientRec."Client Type" = ClientRec."Client Type"::Tenant)) THEN
                        ERROR(Text001, "Client No.");
                    "Client Name" := ClientRec.Name;
                    ;
                END;

                ValidateClientProductGroup;
            end;
        }
        field(2; "Agreement No."; Code[20])
        {
            Enabled = false;
            TableRelation = "Agreement Header".No.;
        }
        field(3; "Start Date"; Date)
        {
        }
        field(4; "Net Sales"; Decimal)
        {
        }
        field(5; "Net Quantity"; Decimal)
        {
        }
        field(6; "Client Name"; Text[50])
        {
        }
        field(7; "Premise No."; Code[20])
        {
            TableRelation = Premise.No.;
        }
        field(8; "Agreement Type"; Option)
        {
            Enabled = false;
            OptionCaption = 'Lease,Sale';
            OptionMembers = Lease,Sale;
        }
        field(9; "Calculate Sales"; Boolean)
        {
        }
        field(10; "Invoice Generated"; Boolean)
        {
        }
        field(11; "End Date"; Date)
        {
        }
        field(12; "Revenue Amount"; Decimal)
        {
        }
        field(20; "Invoice No."; Code[10])
        {
        }
        field(21; "Invoice Posted"; Boolean)
        {
        }
        field(22; "Item Category Code"; Code[20])
        {
            TableRelation = "Item Category".Code;

            trigger OnValidate()
            begin
                IF "Item Category Code" <> xRec."Item Category Code" THEN
                    "Product Group" := '';
                ValidateClientProductGroup;
            end;
        }
        field(23; "Product Group"; Code[20])
        {
            TableRelation = "Product Group".Code WHERE(Item Category Code=FIELD(Item Category Code));

            trigger OnValidate()
            begin
                ValidateClientProductGroup;
            end;
        }
        field(24; "Client Product Group"; Code[20])
        {

            trigger OnLookup()
            var
                ClientProductGrpRec: Record "Client Product Group";
                ClientProductGrpFrm: Form "33016887";
            begin
                ClientProductGrpRec.RESET;
                CLEAR(ClientProductGrpFrm);
                ClientProductGrpRec.SETRANGE("Client No.", "Client No.");
                ClientProductGrpRec.SETRANGE("Product Group", "Product Group");
                ClientProductGrpRec.SETRANGE("Item Category Code", "Item Category Code");
                ClientProductGrpFrm.SETTABLEVIEW(ClientProductGrpRec);
                ClientProductGrpFrm.SETRECORD(ClientProductGrpRec);
                ClientProductGrpFrm.LOOKUPMODE(TRUE);
                IF ClientProductGrpFrm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                    ClientProductGrpFrm.GETRECORD(ClientProductGrpRec);
                    VALIDATE("Client Product Group", ClientProductGrpRec."Client Product Group");
                END;
            end;
        }
        field(25; "Entry No."; Integer)
        {
        }
        field(26; "Client Store Code"; Code[20])
        {
            TableRelation = "Client Store Mapping"."Client Store No." WHERE(Client No.=FIELD(Client No.));
        }
        field(27;"Currency Code";Code[10])
        {
            TableRelation = Currency;
        }
    }

    keys
    {
        key(Key1;"Entry No.")
        {
            Clustered = true;
        }
        key(Key2;"Client No.","Client Store Code","Item Category Code","Product Group")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        ClientRevenueRec: Record "Client Revenue";
        EntryNo: Integer;
    begin
        IF "Entry No." = 0 THEN BEGIN
          CLEAR(EntryNo);
          ClientRevenueRec.RESET;
          IF ClientRevenueRec.FINDLAST THEN
            EntryNo := ClientRevenueRec."Entry No.";
          "Entry No." := EntryNo + 1;
        END;
    end;

    var
        Text001: Label 'Client Type not defined for Client No. %1';
 
    procedure ValidateClientProductGroup()
    var
        ClientProdGroupRec: Record "Client Product Group";
    begin
        IF NOT "Invoice Generated" THEN BEGIN
          IF ClientProdGroupRec.GET("Client No.","Item Category Code","Product Group") THEN
            "Client Product Group" := ClientProdGroupRec."Client Product Group"
          ELSE
            "Client Product Group" := '';
        END;
    end;
 
    procedure UpdateClientStore()
    var
        ClientStoreRec: Record "Client Store Mapping";
    begin
        IF "Client No." = '' THEN
          "Client Store Code" := '';
    end;
}

