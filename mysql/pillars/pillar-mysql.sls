# SALTSTACK PILLAR
mysql:
  root_password: 'password'
  new_user: 'user'
  new_password: 'db_password'
  new_database: 'database'
  buffer_pool_size: '256M'
  backup_dir: '/backup/mysql/'
  replication_user: 'replication_user'
  replication_password: 'replication_password'
  master_server_ip: '192.168.0.2'
  slave_server_ip: '192.168.0.3'
  server_id: 2
  encryption_password: pass