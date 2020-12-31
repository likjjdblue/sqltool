FROM mysql:5.7
WORKDIR /TRS
ADD ./create_database_and_account.sh /TRS
RUN chmod 777 /TRS/create_database_and_account.sh

ENTRYPOINT ["/bin/bash", "-c", "/TRS/create_database_and_account.sh"]
