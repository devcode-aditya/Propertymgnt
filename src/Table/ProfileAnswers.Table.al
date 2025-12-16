table 33016831 "Profile Answers"
{
    Caption = 'Profile Answers';

    fields
    {
        field(1; "Premises No."; Code[20])
        {
            TableRelation = Premise.No.;
        }
        field(2; "Profile Questionnaire Code"; Code[10])
        {
        }
        field(3; "Line No."; Integer)
        {
        }
        field(4; Answer; Text[250])
        {
            CalcFormula = Lookup("Profile Questionnaire Line".Description WHERE(Profile Questionnaire Code =FIELD(Profile Questionnaire Code),
                                                                                 Line No.=FIELD(Line No.)));
            FieldClass = FlowField;
        }
        field(5;"Profile Questionnaire Priority";Option)
        {
            Caption = 'Profile Questionnaire Priority';
            Editable = false;
            OptionCaption = 'Very Low,Low,Normal,High,Very High';
            OptionMembers = "Very Low",Low,Normal,High,"Very High";
        }
        field(6;"Answer Priority";Option)
        {
            OptionCaption = 'Very Low (Hidden),Low,Normal,High,Very High';
            OptionMembers = "Very Low (Hidden)",Low,Normal,High,"Very High";
        }
        field(7;"Last Date Updated";Date)
        {
        }
        field(8;"Questions Answered (%)";Decimal)
        {
        }
        field(9;Comment;Boolean)
        {
        }
        field(10;"Room Code";Code[10])
        {
        }
        field(11;Name;Text[30])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(12;Address;Text[30])
        {
            Caption = 'Address';
            Editable = false;
        }
        field(13;"Address 2";Text[30])
        {
            Caption = 'Address 2';
            Editable = false;
        }
        field(14;City;Text[30])
        {
            Caption = 'City';
            Editable = false;
        }
        field(15;"Post Code";Code[20])
        {
            Caption = 'Post Code';
            Editable = false;
        }
        field(16;"Question Line No.";Integer)
        {
            Caption = 'Question Line No.';
        }
        field(17;"Answer Type";Option)
        {
            Caption = 'Answer Type';
            OptionCaption = 'Check,Text,Number,Boolean,Date';
            OptionMembers = Check,Text,Number,Boolean,Date;
        }
        field(18;"Min. Value";Decimal)
        {
            Caption = 'Min. Value';
        }
        field(19;"Max Value";Decimal)
        {
            Caption = 'Max Value';
        }
        field(20;AnswerCopy;Text[250])
        {
            Caption = 'AnswerCopy';

            trigger OnValidate()
            var
                ldteDate: Date;
                LdecDec: Decimal;
                LblnBool: Boolean;
            begin
                IF (AnswerCopy = '') OR ("Answer Type" = "Answer Type"::Check) THEN
                  EXIT;
                CASE "Answer Type" OF
                  "Answer Type"::Number :
                    IF NOT EVALUATE(LdecDec,AnswerCopy) THEN
                      ERROR(Text002,AnswerCopy)
                    ELSE IF (("Min. Value" <> 0) AND (LdecDec < "Min. Value")) OR
                      (("Max Value" <> 0) AND (LdecDec > "Max Value")) THEN
                      ERROR(Text005,AnswerCopy,"Min. Value","Max Value")
                    ELSE
                      AnswerCopy := FORMAT(LdecDec);
                  "Answer Type"::Date :
                    IF NOT EVALUATE(ldteDate,AnswerCopy) THEN
                      ERROR(Text003,AnswerCopy)
                    ELSE
                      AnswerCopy := FORMAT(ldteDate);
                  "Answer Type"::Boolean :
                    IF NOT EVALUATE(LblnBool,AnswerCopy) THEN
                      ERROR(Text004)
                    ELSE
                      AnswerCopy := FORMAT(LblnBool);
                END;
            end;
        }
    }

    keys
    {
        key(Key1;"Premises No.","Profile Questionnaire Code","Line No.")
        {
            Clustered = true;
        }
        key(Key2;"Premises No.","Answer Priority","Profile Questionnaire Priority")
        {
        }
        key(Key3;"Profile Questionnaire Code","Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        ProfileAnswer: Record "Profile Answers";
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        ProfileQuestnLine2: Record "Profile Questionnaire Line";
        ProfileQuestnLine3: Record "Profile Questionnaire Line";
        rPremises: Record Premise;
    begin
        ProfileQuestnLine.GET("Profile Questionnaire Code","Line No.");
        ProfileQuestnLine.TESTFIELD(Type,ProfileQuestnLine.Type::Answer);
        ProfileQuestnLine2.GET("Profile Questionnaire Code",QuestionLineNo);
        ProfileQuestnLine2.TESTFIELD("Auto Contact Classification",FALSE);
        IF NOT ProfileQuestnLine2."Multiple Answers" THEN BEGIN
          ProfileAnswer.RESET;
          ProfileQuestnLine3.RESET;
          ProfileQuestnLine3.SETRANGE("Profile Questionnaire Code","Profile Questionnaire Code");
          ProfileQuestnLine3.SETRANGE(Type,ProfileQuestnLine3.Type::Question);
          ProfileQuestnLine3.SETFILTER("Line No.", '>%1',ProfileQuestnLine2."Line No.");
          IF ProfileQuestnLine3.FINDFIRST THEN
            ProfileAnswer.SETRANGE("Line No.",ProfileQuestnLine2."Line No.",ProfileQuestnLine3."Line No.")
          ELSE
            ProfileAnswer.SETFILTER("Line No.", '>%1',ProfileQuestnLine2."Line No.");
          ProfileAnswer.SETRANGE("Premises No.","Premises No.");
          ProfileAnswer.SETRANGE("Profile Questionnaire Code","Profile Questionnaire Code");
          IF gRoomNo <> '' THEN
            ProfileAnswer.SETRANGE("Room Code",gRoomNo);
          IF ProfileAnswer.FINDFIRST THEN
            ERROR(Text001,ProfileQuestnLine2.FIELDCAPTION("Multiple Answers"));
        END;

        "Question Line No." := QuestionLineNo();
        CALCFIELDS(Answer);
        AnswerCopy := FORMAT(Answer);
    end;

    var
        gRoomNo: Code[10];
        Text001: Label 'This Question does not allow %1.';
        Text002: Label '%1 is not a numerical value';
        Text003: Label '%1 is not a valid date';
        Text004: Label 'Answer can only be YES or NO';
        Text005: Label '%1 is not allowed (min %2 -  max %3)';
 
    procedure SetRoomNo(lpRoomNo: Code[10])
    begin
        gRoomNo := lpRoomNo;
    end;
 
    procedure QuestionLineNo(): Integer
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
        WITH ProfileQuestnLine DO BEGIN
          RESET;
          SETRANGE("Profile Questionnaire Code",Rec."Profile Questionnaire Code");
          SETFILTER("Line No.",'<%1',Rec."Line No.");
          SETRANGE(Type,Type::Question);
          FINDLAST;
          EXIT("Line No.")
        END;
    end;
 
    procedure Question(): Text[50]
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
        ProfileQuestnLine.GET("Profile Questionnaire Code",QuestionLineNo);
        EXIT(ProfileQuestnLine.Description)
    end;
}

