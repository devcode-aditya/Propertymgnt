table 33016848 "Profile Comment Line"
{

    fields
    {
        field(1; Type; Option)
        {
            OptionCaption = 'Premise,Client';
            OptionMembers = Premise,Client;
        }
        field(2; "No."; Code[20])
        {
        }
        field(3; "Profile Questionnaire Code"; Code[10])
        {
        }
        field(4; "Profile Questionnaire Line No."; Integer)
        {
        }
        field(5; "Line No."; Integer)
        {
        }
        field(6; Date; Date)
        {
        }
        field(7; "Code"; Code[10])
        {
        }
        field(8; Comment; Text[80])
        {
        }
        field(9; "User Id"; Code[20])
        {
            TableRelation = User;
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Profile Questionnaire Code", "Profile Questionnaire Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "User Id" := USERID;
    end;

    trigger OnModify()
    begin
        "User Id" := USERID;
    end;

    trigger OnRename()
    begin
        "User Id" := USERID;
    end;

    procedure SetupNewLine()
    var
        CommentLine: Record "Profile Comment Line";
    begin
        CASE Type OF
            Type::Premise:
                CommentLine.SETRANGE(Type, CommentLine.Type::Premise);
            Type::Client:
                CommentLine.SETRANGE(Type, CommentLine.Type::Client);
        END;
        CommentLine.SETRANGE("No.", "No.");
        CommentLine.SETRANGE("Profile Questionnaire Code", "Profile Questionnaire Code");
        CommentLine.SETRANGE("Profile Questionnaire Line No.", "Profile Questionnaire Line No.");
        IF NOT CommentLine.FIND('-') THEN
            Date := WORKDATE;
    end;
}

