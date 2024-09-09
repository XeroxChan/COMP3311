create table enrolments (
    student text,
    course  text,
    mark    integer check (mark between 0 and 100),
    grade   char(1) check (grade between 'A' and 'E'),
    primary key (student,course)
);
