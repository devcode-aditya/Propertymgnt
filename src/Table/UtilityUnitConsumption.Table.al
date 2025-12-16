table 33016844 "Utility Unit Consumption"
{
    Caption = 'Utility Unit Consumption';
    DrillDownFormID = Form33016866;
    LookupFormID = Form33016866;

    fields
    {
        field(1; "Facility No."; Code[20])
        {
            TableRelation = Facility.No.;

            trigger OnValidate()
            var
                Facility: Record Facility;
            begin
                IF "Facility No." <> '' THEN BEGIN
                    Facility.GET("Facility No.");
                    "Facility Vendor No." := Facility."Facility Vendor";
                    "Facility Description" := Facility.Name;
                    "Maintenance Vendor No." := Facility."Maintenance Vendor";
                    "Meter No." := Facility."Meter No.";
                END ELSE BEGIN
                    "Facility Vendor No." := '';
                    "Facility Description" := '';
                    "Maintenance Vendor No." := '';
                    "Meter No." := '';
                END;
            end;
        }
        field(2; "Client No."; Code[20])
        {

            trigger OnLookup()
            var
                ClientList: Form "33016840";
                FacilityRec: Record Facility;
                ClientRec: Record Customer;
                PremiseRec: Record Premise;
            begin
                IF FacilityRec.GET("Facility No.") THEN BEGIN
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
                            VALIDATE("Client No.", ClientRec."No.");
                        END;
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
                            VALIDATE("Client No.", ClientRec."No.");
                        END;
                    END;
                END ELSE
                    "Client No." := '';
            end;

            trigger OnValidate()
            var
                FacilityRec: Record Facility;
                PremiseRec: Record Premise;
            begin
            end;
        }
        field(3; "Reading Date"; Date)
        {
            NotBlank = true;

            trigger OnValidate()
            begin
                TESTFIELD("Sales Invoice Generated", FALSE);
                TESTFIELD("Purchase Invoice Generated", FALSE);
                UpdateConsumptionDate;
            end;
        }
        field(4; "Unit Consumed"; Decimal)
        {
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                TESTFIELD("Sales Invoice Generated", FALSE);
                TESTFIELD("Purchase Invoice Generated", FALSE);
                IF "Unit Consumed" < 0 THEN
                    ERROR(Text002);

                "Calculated Sales Amount" := CalculatedConsumptionAmount;
                "Calculated Purch. Amount" := CalculateProcurementAmount;
            end;
        }
        field(5; "Calculated Sales Amount"; Decimal)
        {
            Editable = false;

            trigger OnValidate()
            begin
                "Calculated Sales Amount" := CalculatedConsumptionAmount;
                "Calculated Purch. Amount" := CalculateProcurementAmount;
            end;
        }
        field(7; "Due Date"; Date)
        {
            Editable = false;

            trigger OnValidate()
            begin
                UpdateConsumptionDate;
            end;
        }
        field(8; "Grace Period End Date"; Date)
        {
            Editable = false;

            trigger OnValidate()
            begin
                UpdateConsumptionDate;
            end;
        }
        field(9; "Sales Invoice Generated"; Boolean)
        {
        }
        field(10; "Facility Vendor No."; Code[20])
        {
            Editable = false;
            TableRelation = Vendor.No.;
        }
        field(11; "Purchase Invoice Generated"; Boolean)
        {
        }
        field(12; "Calculated Purch. Amount"; Decimal)
        {
            Editable = false;

            trigger OnValidate()
            begin
                "Calculated Purch. Amount" := CalculateProcurementAmount;
            end;
        }
        field(13; "Facility Description"; Text[50])
        {
            Description = 'Text 30 ---> Text 50';
        }
        field(14; "Maintenance Vendor No."; Code[20])
        {
            Editable = false;
            TableRelation = Vendor.No.;
        }
        field(15; "Meter No."; Text[30])
        {
            Editable = false;
        }
        field(16; "Bill No."; Text[50])
        {
        }
        field(17; "Previous Reading"; Integer)
        {
            MinValue = 0;

            trigger OnValidate()
            begin
                UpdateUnitConsumption;
            end;
        }
        field(18; "Current Reading"; Integer)
        {
            MinValue = 0;

            trigger OnValidate()
            begin
                UpdateUnitConsumption;
            end;
        }
        field(19; "Surcharge Amount"; Decimal)
        {
            Editable = false;
        }
        field(20; Temperature; Decimal)
        {
            Description = 'VKC-To record Temp.';
        }
    }

    keys
    {
        key(Key1; "Facility No.", "Client No.", "Reading Date")
        {
            Clustered = true;
            SumIndexFields = "Unit Consumed";
        }
        key(Key2; "Client No.", "Facility No.", "Reading Date")
        {
        }
        key(Key3; "Facility Vendor No.", "Facility No.", "Reading Date")
        {
        }
        key(Key4; "Facility No.", "Maintenance Vendor No.", "Reading Date")
        {
        }
        key(Key5; "Facility No.", "Due Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        UpdateConsumptionDate;
    end;

    trigger OnModify()
    begin
        UpdateConsumptionDate;
        "Calculated Sales Amount" := CalculatedConsumptionAmount;
        "Calculated Purch. Amount" := CalculateProcurementAmount;
    end;

    trigger OnRename()
    begin
        UpdateConsumptionDate;
        "Calculated Sales Amount" := CalculatedConsumptionAmount;
        "Calculated Purch. Amount" := CalculateProcurementAmount;
    end;

    var
        Text001: Label 'Client %1 is not associated with Linked Premise No. %2 of Facility No. %3';
        Text002: Label 'Current Reading must be greater than Previous Reading';

    procedure CalculatedConsumptionAmount(): Decimal
    var
        FacilityPriceRec: Record "Facility Cost/Price Slab";
        FixedCost: Decimal;
        FixedPrice: Decimal;
        FaciltyRec: Record Facility;
        CalculatedAmt: Decimal;
        SalesAmount: Decimal;
        UnitConsumedInSlab: Decimal;
        SurchargeAmount: Decimal;
        SurchargeonFixAmount: Decimal;
    begin
        FacilityPriceRec.RESET;
        FacilityPriceRec.SETCURRENTKEY("Facility Code", Type, "Client No.", "Calculation Type", UOM, "Unit Price");
        FacilityPriceRec.SETRANGE("Facility Code", "Facility No.");
        FacilityPriceRec.SETRANGE(Type, FacilityPriceRec.Type::Client);
        FacilityPriceRec.SETRANGE("Client No.", "Client No.");
        FacilityPriceRec.SETRANGE("Calculation Type", FacilityPriceRec."Calculation Type"::Fixed);
        FacilityPriceRec.SETFILTER("Start Date", '<=%1', "Reading Date");
        FacilityPriceRec.SETFILTER("End Date", '>=%1', "Reading Date");
        IF FacilityPriceRec.FINDLAST THEN BEGIN
            FixedPrice := FacilityPriceRec."Unit Price";
        END ELSE BEGIN
            FacilityPriceRec.SETRANGE(Type, FacilityPriceRec.Type::All);
            FacilityPriceRec.SETRANGE("Client No.");
            IF FacilityPriceRec.FINDLAST THEN BEGIN
                FixedPrice := FacilityPriceRec."Unit Price";
                SurchargeonFixAmount := (("Unit Consumed" * FacilityPriceRec."Surcharge %") / 100);
            END;
        END;

        FaciltyRec.GET("Facility No.");
        IF FaciltyRec."Calculation Priority" = FaciltyRec."Calculation Priority"::"Unit Wise" THEN BEGIN
            FacilityPriceRec.RESET;
            FacilityPriceRec.SETCURRENTKEY("Facility Code", Type, "Client No.", "Calculation Type", UOM, "Unit Price");
            FacilityPriceRec.SETRANGE("Facility Code", "Facility No.");
            FacilityPriceRec.SETRANGE(Type, FacilityPriceRec.Type::Client);
            FacilityPriceRec.SETRANGE("Client No.", "Client No.");
            FacilityPriceRec.SETRANGE("Calculation Type", FacilityPriceRec."Calculation Type"::"Unit Wise");
            FacilityPriceRec.SETFILTER("Start Date", '<=%1', "Reading Date");
            FacilityPriceRec.SETFILTER("End Date", '>=%1', "Reading Date");
            FacilityPriceRec.SETFILTER("Min. Unit Consumption", '<=%1', "Unit Consumed");
            FacilityPriceRec.SETFILTER("Max. Unit Consumption", '>=%1', "Unit Consumed");
            IF FacilityPriceRec.FINDLAST THEN BEGIN
                CalculatedAmt := FacilityPriceRec."Unit Price" * "Unit Consumed";
                SurchargeAmount := (("Unit Consumed" * FacilityPriceRec."Surcharge %") / 100);
            END ELSE BEGIN
                FacilityPriceRec.SETRANGE(Type, FacilityPriceRec.Type::All);
                FacilityPriceRec.SETRANGE("Client No.");
                IF FacilityPriceRec.FINDLAST THEN BEGIN
                    CalculatedAmt := FacilityPriceRec."Unit Price" * "Unit Consumed";
                    SurchargeAmount := (("Unit Consumed" * FacilityPriceRec."Surcharge %") / 100);
                END;
            END;
        END ELSE BEGIN
            FacilityPriceRec.RESET;
            FacilityPriceRec.SETCURRENTKEY("Facility Code", Type, "Client No.", "Calculation Type", UOM, "Unit Price");
            FacilityPriceRec.SETRANGE("Facility Code", "Facility No.");
            FacilityPriceRec.SETRANGE(Type, FacilityPriceRec.Type::Client);
            FacilityPriceRec.SETRANGE("Client No.", "Client No.");
            FacilityPriceRec.SETRANGE("Calculation Type", FacilityPriceRec."Calculation Type"::"Slab Wise");
            FacilityPriceRec.SETFILTER("Start Date", '<=%1', "Reading Date");
            FacilityPriceRec.SETFILTER("End Date", '>=%1', "Reading Date");
            IF FacilityPriceRec.FINDSET THEN BEGIN
                REPEAT
                    CLEAR(UnitConsumedInSlab);
                    IF FacilityPriceRec."Max. Unit Consumption" <= "Unit Consumed" THEN BEGIN
                        UnitConsumedInSlab := (FacilityPriceRec."Max. Unit Consumption" - FacilityPriceRec."Min. Unit Consumption") + 1;
                        CalculatedAmt += FacilityPriceRec."Unit Price" * UnitConsumedInSlab;
                        SurchargeAmount += ((UnitConsumedInSlab * FacilityPriceRec."Surcharge %") / 100);
                    END ELSE BEGIN
                        IF FacilityPriceRec."Min. Unit Consumption" <= "Unit Consumed" THEN BEGIN
                            UnitConsumedInSlab := ("Unit Consumed" - FacilityPriceRec."Min. Unit Consumption") + 1;
                            CalculatedAmt += FacilityPriceRec."Unit Price" * UnitConsumedInSlab;
                            SurchargeAmount += ((UnitConsumedInSlab * FacilityPriceRec."Surcharge %") / 100);
                        END;
                    END;
                UNTIL FacilityPriceRec.NEXT = 0;
            END ELSE BEGIN
                FacilityPriceRec.SETRANGE(Type, FacilityPriceRec.Type::All);
                FacilityPriceRec.SETRANGE("Client No.");
                IF FacilityPriceRec.FINDSET THEN BEGIN
                    REPEAT
                        CLEAR(UnitConsumedInSlab);
                        IF FacilityPriceRec."Max. Unit Consumption" <= "Unit Consumed" THEN BEGIN
                            UnitConsumedInSlab := (FacilityPriceRec."Max. Unit Consumption" - FacilityPriceRec."Min. Unit Consumption") + 1;
                            CalculatedAmt += FacilityPriceRec."Unit Price" * UnitConsumedInSlab;
                            SurchargeAmount += ((UnitConsumedInSlab * FacilityPriceRec."Surcharge %") / 100);
                        END ELSE BEGIN
                            IF FacilityPriceRec."Min. Unit Consumption" <= "Unit Consumed" THEN BEGIN
                                UnitConsumedInSlab := ("Unit Consumed" - FacilityPriceRec."Min. Unit Consumption") + 1;
                                CalculatedAmt += FacilityPriceRec."Unit Price" * UnitConsumedInSlab;
                                SurchargeAmount += ((UnitConsumedInSlab * FacilityPriceRec."Surcharge %") / 100);
                            END;
                        END;
                    UNTIL FacilityPriceRec.NEXT = 0;
                END;
            END;
        END;

        SalesAmount := ROUND((FixedPrice + CalculatedAmt), 0.01);
        "Surcharge Amount" := ROUND(SurchargeonFixAmount + SurchargeAmount, 0.01);
        EXIT(SalesAmount);
    end;

    procedure UpdateConsumptionDate()
    var
        FacilityRec: Record Facility;
    begin
        IF ("Facility No." <> '') AND ("Reading Date" <> 0D) THEN BEGIN
            FacilityRec.GET("Facility No.");
            IF FORMAT(FacilityRec."Due Date Calculation") <> '' THEN
                "Due Date" := CALCDATE(FORMAT(FacilityRec."Due Date Calculation"), "Reading Date");
            IF (FORMAT(FacilityRec."Grace Period") <> '') AND ("Due Date" <> 0D) THEN
                "Grace Period End Date" := CALCDATE(FORMAT(FacilityRec."Grace Period"), "Due Date");
        END;
    end;

    procedure CalculateProcurementAmount(): Decimal
    var
        FacilityPriceRec: Record "Facility Cost/Price Slab";
        FixedPrice: Decimal;
        FaciltyRec: Record Facility;
        CalculatedAmt: Decimal;
        PurchaseAmount: Decimal;
        UnitConsumedInSlab: Decimal;
    begin
        FacilityPriceRec.RESET;
        FacilityPriceRec.SETCURRENTKEY("Facility Code", Type, "Client No.", "Calculation Type", UOM, "Unit Cost");
        FacilityPriceRec.SETRANGE("Facility Code", "Facility No.");
        FacilityPriceRec.SETRANGE(Type, FacilityPriceRec.Type::Client);
        FacilityPriceRec.SETRANGE("Client No.", "Client No.");
        FacilityPriceRec.SETRANGE("Calculation Type", FacilityPriceRec."Calculation Type"::Fixed);
        FacilityPriceRec.SETFILTER("Start Date", '<=%1', "Reading Date");
        FacilityPriceRec.SETFILTER("End Date", '>=%1', "Reading Date");
        IF FacilityPriceRec.FINDLAST THEN BEGIN
            FixedPrice := FacilityPriceRec."Unit Cost";
        END ELSE BEGIN
            FacilityPriceRec.SETRANGE(Type, FacilityPriceRec.Type::All);
            FacilityPriceRec.SETRANGE("Client No.");
            IF FacilityPriceRec.FINDLAST THEN BEGIN
                FixedPrice := FacilityPriceRec."Unit Cost";
            END;
        END;

        FaciltyRec.GET("Facility No.");
        IF FaciltyRec."Calculation Priority" = FaciltyRec."Calculation Priority"::"Unit Wise" THEN BEGIN
            FacilityPriceRec.RESET;
            FacilityPriceRec.SETCURRENTKEY("Facility Code", Type, "Client No.", "Calculation Type", UOM, "Unit Cost");
            FacilityPriceRec.SETRANGE("Facility Code", "Facility No.");
            FacilityPriceRec.SETRANGE(Type, FacilityPriceRec.Type::Client);
            FacilityPriceRec.SETRANGE("Client No.", "Client No.");
            FacilityPriceRec.SETRANGE("Calculation Type", FacilityPriceRec."Calculation Type"::"Unit Wise");
            FacilityPriceRec.SETFILTER("Start Date", '<=%1', "Reading Date");
            FacilityPriceRec.SETFILTER("End Date", '>=%1', "Reading Date");
            FacilityPriceRec.SETFILTER("Min. Unit Consumption", '<=%1', "Unit Consumed");
            FacilityPriceRec.SETFILTER("Max. Unit Consumption", '>=%1', "Unit Consumed");
            IF FacilityPriceRec.FINDLAST THEN BEGIN
                CalculatedAmt := FacilityPriceRec."Unit Cost" * "Unit Consumed";
            END ELSE BEGIN
                FacilityPriceRec.SETRANGE(Type, FacilityPriceRec.Type::All);
                FacilityPriceRec.SETRANGE("Client No.");
                IF FacilityPriceRec.FINDLAST THEN
                    CalculatedAmt := FacilityPriceRec."Unit Cost" * "Unit Consumed";
            END;
        END ELSE BEGIN
            FacilityPriceRec.RESET;
            FacilityPriceRec.SETCURRENTKEY("Facility Code", Type, "Client No.", "Calculation Type", UOM, "Unit Cost");
            FacilityPriceRec.SETRANGE("Facility Code", "Facility No.");
            FacilityPriceRec.SETRANGE(Type, FacilityPriceRec.Type::Client);
            FacilityPriceRec.SETRANGE("Client No.", "Client No.");
            FacilityPriceRec.SETRANGE("Calculation Type", FacilityPriceRec."Calculation Type"::"Slab Wise");
            FacilityPriceRec.SETFILTER("Start Date", '<=%1', "Reading Date");
            FacilityPriceRec.SETFILTER("End Date", '>=%1', "Reading Date");
            IF FacilityPriceRec.FINDSET THEN BEGIN
                REPEAT
                    CLEAR(UnitConsumedInSlab);
                    IF FacilityPriceRec."Max. Unit Consumption" <= "Unit Consumed" THEN BEGIN
                        UnitConsumedInSlab := (FacilityPriceRec."Max. Unit Consumption" - FacilityPriceRec."Min. Unit Consumption") + 1;
                        CalculatedAmt += FacilityPriceRec."Unit Cost" * UnitConsumedInSlab;
                    END ELSE BEGIN
                        IF FacilityPriceRec."Min. Unit Consumption" <= "Unit Consumed" THEN BEGIN
                            UnitConsumedInSlab := ("Unit Consumed" - FacilityPriceRec."Min. Unit Consumption") + 1;
                            CalculatedAmt += FacilityPriceRec."Unit Cost" * UnitConsumedInSlab;
                        END;
                    END;
                UNTIL FacilityPriceRec.NEXT = 0;
            END ELSE BEGIN
                FacilityPriceRec.SETRANGE(Type, FacilityPriceRec.Type::All);
                FacilityPriceRec.SETRANGE("Client No.");
                IF FacilityPriceRec.FINDSET THEN BEGIN
                    REPEAT
                        CLEAR(UnitConsumedInSlab);
                        IF FacilityPriceRec."Max. Unit Consumption" <= "Unit Consumed" THEN BEGIN
                            UnitConsumedInSlab := (FacilityPriceRec."Max. Unit Consumption" - FacilityPriceRec."Min. Unit Consumption") + 1;
                            CalculatedAmt += FacilityPriceRec."Unit Cost" * UnitConsumedInSlab;
                        END ELSE BEGIN
                            IF FacilityPriceRec."Min. Unit Consumption" <= "Unit Consumed" THEN BEGIN
                                UnitConsumedInSlab := ("Unit Consumed" - FacilityPriceRec."Min. Unit Consumption") + 1;
                                CalculatedAmt += FacilityPriceRec."Unit Cost" * UnitConsumedInSlab;
                            END;
                        END;
                    UNTIL FacilityPriceRec.NEXT = 0;
                END;
            END;
        END;

        PurchaseAmount := ROUND((FixedPrice + CalculatedAmt), 0.01);
        EXIT(PurchaseAmount);
    end;

    procedure UpdateUnitConsumption()
    begin
        IF "Current Reading" <> 0 THEN
            VALIDATE("Unit Consumed", "Current Reading" - "Previous Reading");
    end;
}

