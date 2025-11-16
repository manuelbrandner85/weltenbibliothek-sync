module.exports = {
  apps: [
    {
      name: 'weltenbibliothek',
      script: 'npx',
      args: 'wrangler pages dev dist --d1=weltenbibliothek_db_v2 --r2=weltenbibliothek-media --local --ip 0.0.0.0 --port 3000',
      env: {
        NODE_ENV: 'development',
        PORT: 3000
      },
      watch: false,
      instances: 1,
      exec_mode: 'fork'
    }
  ]
}
