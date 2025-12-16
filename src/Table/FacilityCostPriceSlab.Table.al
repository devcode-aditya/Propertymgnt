table 33016843 "Facility Cost/Price Slab"
{
    Caption = 'Facility Cost/Price Slab';

    fields
    {
        field(1; "Facility Code"; Code[20])
        {
            TableRelation = Facility;
        }
        field(2; Type; Option)
        {
            OptionCaption = 'All,Client';
            OptionMembers = All,Client;

            trigger OnValidate()
            begin
                IF Type = Type::All THEN
                    "Client No." := '';
            end;
        }
        field(3; "Client No."; Code[20])
        {
            TableRelation = Customer;

            trigger OnLookup()
            var
                FacilityRec: Record Facility;
                PremiseRec: Record Premise;
                ClientRec: Record Customer;
                ClientList: Form "33016840";
            begin
                IF Type = Type::Client THEN BEGIN
                    IF FacilityRec.GET("Facility Code") THEN
                        IF (FacilityRec."Linked Premise Code" <> '') AND PremiseRec.GET(FacilityRec."Linked Premise Code") THEN BEGIN
                            CLEAR(ClientList);
                            ClientRec.RESET;
                            ClientRec.SETRANGE("No.", PremiseRec."Client No.");
                            ClientList.SETTABLEVIEW(ClientRec);
                            ClientList.SETRECORD(ClientRec);
                            ClientList.EDITABLE(FALSE);
                            ClientList.LOOKUPMODE(TRUE);
                            IF ClientList.RUNMODAL = ACTION::LookupOK THEN BEGIN
                                ClientList.GETRECORD(ClientRec);
                                "Client No." := ClientRec."No.";
                            END
                        END ELSE BEGIN
                            CLEAR(ClientList);
                            ClientRec.RESET;
                            ClientRec.SETCURRENTKEY(ClientRec."No.");
                            ClientList.SETTABLEVIEW(ClientRec);
                            ClientList.SETRECORD(ClientRec);
                            ClientList.EDITABLE(FALSE);
                            ClientList.LOOKUPMODE(TRUE);
                            IF ClientList.RUNMODAL = ACTION::LookupOK THEN BEGIN
                                ClientList.GETRECORD(ClientRec);
                                "Client No." := ClientRec."No.";
                            END;
                        END;
                END ELSE
                    "Client No." := '';
            end;

            trigger OnValidate()
            var
                FacilityRec: Record Facility;
                PremiseRec: Record Premise;
                ClientRec: Record Customer;
            begin
                IF Type = Type::All THEN
                    "Client No." := ''
                ELSE BEGIN
                    IF "Client No." <> '' THEN
                        ClientRec.GET("Client No.");
                    IF FacilityRec.GET("Facility Code") THEN BEGIN
                        IF (FacilityRec."Linked Premise Code" <> '') AND PremiseRec.GET(FacilityRec."Linked Premise Code") THEN BEGIN
                            IF "Client No." <> PremiseRec."Client No." THEN
                                ERROR(Text001, "Client No.", FacilityRec."Linked Premise Code", "Facility Code");
                        END ELSE
                            "Client No." := ''
                    END
                    ELSE
                        "Client No." := '';

                END;

                "Min. Unit Consumption" := 0;
                "Max. Unit Consumption" := 0;
            end;
        }
        field(4; "Start Date"; Date)
        {
            NotBlank = true;

            trigger OnValidate()
            begin
                IF "End Date" <> 0D THEN
                    IF "Start Date" > "End Date" THEN
                        ERROR(Text33016800);

                IF "Start Date" = 0D THEN
                    "End Date" := 0D;

                "Min. Unit Consumption" := 0;
                "Max. Unit Consumption" := 0;
            end;
        }
        field(5; "End Date"; Date)
        {
            NotBlank = true;

            trigger OnValidate()
            begin
                IF "End Date" <> 0D THEN BEGIN
                    IF "Start Date" = 0D THEN
                        ERROR(Text33016801);
                    IF "Start Date" > "End Date" THEN
                        ERROR(Text33016800);
                END;

                "Min. Unit Consumption" := 0;
                "Max. Unit Consumption" := 0;
            end;
        }
        field(6; "Calculation Type"; Option)
        {
            Caption = 'Calculation Type';
            OptionCaption = 'Unit Wise,Fixed,Slab Wise';
            OptionMembers = "Unit Wise","Fixed","Slab Wise";

            trigger OnValidate()
            begin

                "Min. Unit Consumption" := 0;
                "Max. Unit Consumption" := 0;
            end;
        }
        field(7; "Unit Cost"; Decimal)
        {
            DecimalPlaces = 0 : 3;

            trigger OnValidate()
            begin
                IF "Max. Unit Consumption" <> 0 THEN
                    IF "Max. Unit Consumption" < "Min. Unit Consumption" THEN
                        ERROR(Text33016910, FIELDNAME("Max. Unit Consumption"), FIELDNAME("Min. Unit Consumption"));
            end;
        }
        field(8; "Unit Price"; Decimal)
        {
            DecimalPlaces = 0 : 3;

            trigger OnValidate()
            begin
                IF "Max. Unit Consumption" <> 0 THEN
                    IF "Max. Unit Consumption" < "Min. Unit Consumption" THEN
                        ERROR(Text33016910, FIELDNAME("Max. Unit Consumption"), FIELDNAME("Min. Unit Consumption"));
            end;
        }
        field(9; UOM; Code[10])
        {
            TableRelation = "Unit of Measure";
        }
        field(10; "Min. Unit Consumption"; Decimal)
        {

            trigger OnValidate()
            begin
                ValidateUnits;
            end;
        }
        field(11; "Max. Unit Consumption"; Decimal)
        {

            trigger OnValidate()
            begin
                ValidateUnits;
            end;
        }
        field(12; "Surcharge %"; Decimal)
        {
        }
    }

    keys
    {
        key(Key1; "Facility Code", Type, "Client No.", "Start Date", "End Date", "Min. Unit Consumption", "Max. Unit Consumption", "Calculation Type", UOM)
        {
            Clustered = true;
        }
        key(Key2; "Facility Code", Type, "Client No.", "Calculation Type", UOM, "Unit Price")
        {
        }
        key(Key3; "Facility Code", Type, "Client No.", "Calculation Type", UOM, "Unit Cost")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        IF Type <> Type::All THEN BEGIN
            TESTFIELD("Client No.");
            TESTFIELD("Start Date");
            TESTFIELD("End Date");
        END;
    end;

    var
        Text001: Label 'Client %1 is not associated with Linked Premise No. %2 of Facility No. %3';
        Text33016800: Label 'End Date must be greater than Start Date';
        Text33016801: Label 'Start Date must not be blank';
        Text33016910: Label '%1 must be greater than %2';

    procedure ValidateUnits()
    var
        FacilityCostPriceSlab: Record "Facility Cost/Price Slab";
    begin
        IF "Min. Unit Consumption" <> 0 THEN BEGIN
            FacilityCostPriceSlab.SETRANGE("Facility Code", "Facility Code");
            FacilityCostPriceSlab.SETRANGE(Type, Type);
            FacilityCostPriceSlab.SETRANGE("Client No.", "Client No.");
            FacilityCostPriceSlab.SETRANGE("Start Date", "Start Date");
            FacilityCostPriceSlab.SETRANGE("End Date", "End Date");
            FacilityCostPriceSlab.SETRANGE("Calculation Type", "Calculation Type");
            FacilityCostPriceSlab.SETRANGE(UOM, UOM);
            FacilityCostPriceSlab.SETFILTER("Min. Unit Consumption", '<>%1', "Min. Unit Consumption");
            IF FacilityCostPriceSlab.FINDSET THEN BEGIN
                REPEAT
                    IF "Min. Unit Consumption" <= FacilityCostPriceSlab."Max. Unit Consumption" THEN
                        ERROR(Text33016910, FIELDNAME("Min. Unit Consumption"), FacilityCostPriceSlab."Max. Unit Consumption");
                UNTIL FacilityCostPriceSlab.NEXT = 0;
            END;
        END;

        IF "Max. Unit Consumption" <> 0 THEN
            IF "Max. Unit Consumption" < "Min. Unit Consumption" THEN
                ERROR(Text33016910, FIELDNAME("Max. Unit Consumption"), FIELDNAME("Min. Unit Consumption"));
    end;
}

