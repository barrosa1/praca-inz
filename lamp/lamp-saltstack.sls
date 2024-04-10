#Wczytanie pillara z secretami
base:
  '*':
    - /pillars/pillar-lamp
# Aktualizacja i upgrade pakietów
    - update_and_upgrade:
        pkg.uptodate: []
#Instalacja firewalla
    - install_firewall:
        pkg.installed:
          - name: ufw
#Instalacja pakietów LAMP
    - install_lamp_packages:
        pkg.installed:
          - pkgs:
            - apache2
            - mariadb-server
            - php
            - libapache2-mod-php
            - php-mysql
#Ustawienie reguł dla firewalla
    - configure_firewall:
        cmd.run:
          - name: ufw allow 'Apache'
          - name: ufw allow 'OpenSSH'
#Włączenie firewalla
    - enable_firewall:
        cmd.run:
          - name: ufw enable
#Usunięcie domyślnej strony Apache
    - remove_default_apache_page:
        file.absent:
          - name: /var/www/html/index.html
#Kopiowanie nowego pliku index.php
    - copy_new_index_php:
        file.managed:
          - name: /var/www/html/index.php
          - source: salt://tmp/index.php
#Utworzenie bazy danych
    - create_database:
        mysql_database.present:
          - name: "{{ pillar['db_name'] }}"
#Utworzenie użytkownika bazy danych
    - create_database_user:
        mysql_user.present:
          - name: "{{ pillar['db_user'] }}"
          - password: "{{ pillar['db_pass'] }}"
          - host: localhost
          - grant: ALL PRIVILEGES
#Załadowanie danych do bazy
    - load_data_into_database:
        cmd.run:
          - name: mysql -u {{ pillar['db_user'] }} -p{{ pillar['db_pass'] }} {{ pillar['db_name'] }} < /tmp/data.sql
#Konfiguracja PHP
    - configure_php_memory_limit:
        file.replace:
          - name: /etc/php/8.3/apache2/php.ini
          - pattern: '^memory_limit ='
          - repl: 'memory_limit = {{ memory_limit }}'
    - configure_php_upload_max_filesize:
        file.replace:
          - name: /etc/php/8.3/apache2/php.ini
          - pattern: '^upload_max_filesize ='
          - repl: 'upload_max_filesize = {{ upload_max_filesize }}'
    - configure_php_max_execution_time:
        file.replace:
          - name: /etc/php/8.3/apache2/php.ini
          - pattern: '^max_execution_time ='
          - repl: 'max_execution_time = {{ max_execution_time }}'
#Uruchomienie i włączenie serwisów przy starcie systemu
    - start_and_enable_services:
        service.running:
          - names:
            - apache2
            - mariadb
          - enable: True
#Testowanie konfiguracji
    - test_configuration:
        cmd.run:
          - name: curl -I http://localhost