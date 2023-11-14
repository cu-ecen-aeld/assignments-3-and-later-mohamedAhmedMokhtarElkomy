#include<syslog.h>
#include<stdio.h>

int main(int argc, char **argv){    

    openlog("", LOG_PID, LOG_USER);

    if(argc < 2){
        syslog(LOG_ERR, "String argument not found");
        closelog();
        return 1;
    }

    // char *writefile = argv[1];
    char *writestr = argv[2];

    FILE *file;
    file  = fopen (argv[1], "w");
    if(!file){
        syslog(LOG_ERR, "directory not found");
        // fclose(file);
        closelog();
        return 1;
    }
    syslog(LOG_DEBUG,  "Writing %s to %s", argv[2], argv[1]);
    fprintf(file, argv[2]);
    fclose(file);




    closelog();
    return 0;
}