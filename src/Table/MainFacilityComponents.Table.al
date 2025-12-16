table 33016862 "Main Facility Components"
{
    PasteIsValid = false;

    fields
    {
        field(1; "Main Facility No."; Code[20])
        {
            TableRelation = Facility;
        }
        field(2; "Facility No."; Code[20])
        {
            NotBlank = true;
            TableRelation = Facility.No. WHERE (Main/Component Facility=FILTER(' '));

            trigger OnValidate()
            begin
                IF ("Facility No." = '') OR ("Main Facility No." = '') THEN
                  EXIT;
                LockFacility;

                MainFacility.GET("Main Facility No.");
                IF MainFacility."Main/Component Facility" = MainFacility."Main/Component Facility"::Component THEN
                  ERROR(Text003,"Main Facility No.");

                IF "Facility No." = "Main Facility No." THEN
                  ERROR(Text001,"Facility No.");

                MainFacilityComp.SETRANGE("Main Facility No.","Facility No.");
                IF MainFacilityComp.FINDFIRST THEN
                  ERROR(Text001,"Facility No.");

                MainFacilityComp.SETRANGE("Main Facility No.");
                MainFacilityComp.SETCURRENTKEY("Facility No.");
                MainFacilityComp.SETRANGE("Facility No.","Facility No.");
                IF MainFacilityComp.FIND('-') THEN
                  ERROR(Text002,"Facility No.");

                MainFacility.GET("Facility No.");
                Description := MainFacility.Name;

                UpdateMainFacility(MainFacility,2);
            end;
        }
        field(3;Description;Text[50])
        {
        }
    }

    keys
    {
        key(Key1;"Main Facility No.","Facility No.")
        {
            Clustered = true;
        }
        key(Key2;"Facility No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        LockFacility;
        IF "Facility No." <> '' THEN BEGIN
          MainFacility.GET("Facility No.");
          UpdateMainFacility(MainFacility,0);
        END;
    end;

    trigger OnRename()
    begin
        ERROR(Text000,TABLECAPTION);
    end;

    var
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'Facility No. %1  is Main Facility';
        Text002: Label 'Facility No. %1  is a Component Facility';
        MainFacility: Record Facility;
        MainFacilityComp: Record "Main Facility Components";
        Text003: Label 'Facility No. %1  is not a Main Facility';

    local procedure LockFacility()
    begin
        MainFacility.LOCKTABLE;
    end;

    local procedure UpdateMainFacility(var MainFacility: Record Facility;ComponentType: Option " ",Main,Component)
    var
        Facility2: Record Facility;
    begin
        IF ComponentType = ComponentType::" " THEN BEGIN
          MainFacility."Main/Component Facility" := MainFacility."Main/Component Facility"::" ";
          MainFacility."Ref Main Facility" := '';
        END;
        IF ComponentType = ComponentType::Component THEN BEGIN
          MainFacility."Ref Main Facility" := "Main Facility No.";
          MainFacility."Main/Component Facility" := MainFacility."Main/Component Facility"::Component;
        END;
        MainFacility.MODIFY(TRUE);

        MainFacility.RESET;
        MainFacility.SETCURRENTKEY("Ref Main Facility");
        MainFacility.SETRANGE("Ref Main Facility","Main Facility No.");
        MainFacility.SETRANGE("Main/Component Facility",MainFacility."Main/Component Facility"::Component);

        Facility2.GET("Main Facility No.");
        IF MainFacility.FIND('=><') THEN BEGIN
          IF Facility2."Main/Component Facility" <> Facility2."Main/Component Facility"::Main THEN BEGIN
            Facility2."Main/Component Facility" := Facility2."Main/Component Facility"::Main;
            Facility2."Ref Main Facility" := '';
            Facility2.MODIFY(TRUE);
          END;
        END ELSE BEGIN
          Facility2."Main/Component Facility" := Facility2."Main/Component Facility"::" ";
          Facility2."Ref Main Facility" := '';
          Facility2.MODIFY(TRUE);
        END;
    end;
}

