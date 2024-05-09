#Wczytanie pillara z secretami
base:
  '*':
    - /pillars/pillar-mysql
# Uruchomienie usługi MySQL
    - start_mysql_service:
        service.running:
          - name: mysql
          - enable: True
          - watch:
            - file: /etc/mysql/my.cnf
# Stworzenie nowej bazy danych
    - create_new_database:
        mysql_database.present:
          - name: "{{ pillar['mysql']['new_database'] }}"
          - connection_user: root
          - connection_pass: "{{ pillar['mysql']['root_password'] }}"
# Stworzenie nowego użytkownika
    - create_new_user:
        mysql_user.present:
          - name: "{{ pillar['mysql']['new_user'] }}"
          - password: "{{ pillar['mysql']['new_password'] }}"
          - host: localhost
          - connection_user: root
          - connection_pass: "{{ pillar['mysql']['root_password'] }}"
# Ustawienie rozmiaru bufora
    - set_buffer_size:
        file.replace:
          - name: /etc/mysql/my.cnf
          - pattern: '^innodb_buffer_pool_size'
          - repl: "innodb_buffer_pool_size = {{ pillar['mysql']['buffer_pool_size'] }}"
# Konfiguracja logów binarnych
    - configure_binary_logs:
        file.append:
          - name: /etc/mysql/my.cnf
          - text: 'log_bin = /var/log/mysql/mysql-bin.log'
# Nadanie uprawnień użytkownikowi
    - grant_user_privileges:
        mysql_grants.present:
          - grant: ALL PRIVILEGES
          - database: "{{ pillar['mysql']['new_database'] }}.*"
          - user: "{{ pillar['mysql']['new_user'] }}"
          - host: localhost
          - connection_user: root
          - connection_pass: "{{ pillar['mysql']['root_password'] }}"
# Konfiguracja replikacji bazy danych
    - configure_database_replication: |
        {% if grains['host'] == pillar['mysql']['master_server_ip'] %}
        - master_server_config:
            file.replace:
              - name: /etc/mysql/my.cnf
              - pattern: '^server-id'
              - repl: 'server-id = 1'
        {% endif %}
        - create_replication_user:
            mysql_user.present:
              - name: "{{ pillar['mysql']['replication_user'] }}"
              - password: "{{ pillar['mysql']['replication_password'] }}"
              - host: '%'
              - connection_user: root
              - connection_pass: "{{ pillar['mysql']['root_password'] }}"
        - grant_replication_privileges:
            mysql_grants.present:
              - grant: REPLICATION SLAVE
              - database: '*.*'
              - user: "{{ pillar['mysql']['replication_user'] }}"
              - host: '%'
              - connection_user: root
              - connection_pass: "{{ pillar['mysql']['root_password'] }}"
        {% endif %}
        {% if grains['host'] == pillar['mysql']['slave_server_ip'] %}
        - slave_server_config:
            file.replace:
              - name: /etc/mysql/my.cnf
              - pattern: '^server-id'
              - repl: 'server-id = {{ pillar['mysql']['server_id'] }}'
        - configure_slave_server:
            cmd.run:
              - name: |
                  mysql -u root -p'{{ pillar['mysql']['root_password'] }}' -e "CHANGE MASTER TO MASTER_HOST='{{ pillar['mysql']['master_server_ip'] }}', MASTER_USER='{{ pillar['mysql']['replication_user'] }}', MASTER_PASSWORD='{{ pillar['mysql']['replication_password'] }}', MASTER_LOG_FILE='mysql-bin.000001';"
                  mysql -u root -p'{{ pillar['mysql']['root_password'] }}' -e "START SLAVE;"
        {% endif %}
# Backup bazy danych
    - backup_database:
        cmd.run:
          - name: mysqldump -u root -p'{{ pillar['mysql']['root_password'] }}' {{ pillar['mysql']['new_database'] }} > {{ pillar['mysql']['backup_dir'] }}/backup.sql
        file.managed:
          - name: "{{ pillar['mysql']['backup_dir'] }}/backup.sql"
          - mode: 600
# Instalacja OpenSSL do szyfrowania
    - install_openssl:
        pkg.installed:
          - name: openssl
# Szyfrowanie kopii zapasowej
    - encrypt_backup:
        # Add your encryption command here