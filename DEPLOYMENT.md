# WordPress + Next.js Deployment Guide

Hướng dẫn đầy đủ để build, deploy và quản lý hệ thống WordPress + Next.js với Docker.

## Yêu cầu hệ thống

- Docker Engine 20.10+
- Docker Compose 2.0+
- Bash shell
- 2GB RAM minimum
- 10GB disk space

## Cấu trúc thư mục

```
wordpress/
├── scripts/           # Build & deployment scripts
│   ├── build.sh      # Build Docker images
│   ├── push-dockerhub.sh  # Push to Docker Hub
│   ├── deploy.sh     # Deploy stack
│   ├── export-data.sh     # Export database + uploads
│   └── import-data.sh     # Import database + uploads
├── frontend/         # Next.js application
├── wp-content/       # WordPress content
├── docker-compose.yml
├── Dockerfile        # WordPress backend
└── .env.example      # Environment template
```

## Bước 1: Cấu hình môi trường

### 1.1. Tạo file .env

```bash
cp .env.example .env
nano .env
```

Cập nhật các giá trị:
- `DOCKER_USERNAME`: Tên Docker Hub của bạn
- `MYSQL_ROOT_PASSWORD`: Mật khẩu root MySQL
- `MYSQL_PASSWORD`: Mật khẩu user WordPress
- `WP_HOME`: URL của WordPress (production)

### 1.2. Tạo file frontend/.env.production

```bash
cp frontend/.env.local frontend/.env.production
nano frontend/.env.production
```

Cập nhật:
- `WC_API_URL`: URL backend (internal: http://wordpress)
- `WC_CONSUMER_KEY`: WooCommerce API key
- `WC_CONSUMER_SECRET`: WooCommerce API secret

## Bước 2: Build Docker Images

### 2.1. Build local

```bash
./scripts/build.sh 1.0.0
```

Script sẽ:
- Build backend image (WordPress)
- Build frontend image (Next.js)
- Tag với version và latest

### 2.2. Kiểm tra images

```bash
docker images | grep wordpress
docker images | grep nextjs
```

## Bước 3: Push lên Docker Hub

### 3.1. Login Docker Hub

```bash
docker login
```

### 3.2. Push images

```bash
export DOCKER_USERNAME="your-username"
./scripts/push-dockerhub.sh 1.0.0
```

Images sẽ được push lên:
- `your-username/wordpress-backend:1.0.0`
- `your-username/wordpress-backend:latest`
- `your-username/nextjs-frontend:1.0.0`
- `your-username/nextjs-frontend:latest`

## Bước 4: Deploy Production

### 4.1. Trên server mới

```bash
# Clone repository (hoặc copy files)
git clone <your-repo>
cd wordpress

# Cấu hình .env
cp .env.example .env
nano .env

# Deploy
export DOCKER_USERNAME="your-username"
./scripts/deploy.sh 1.0.0
```

### 4.2. Kiểm tra services

```bash
docker-compose ps
docker-compose logs -f
```

Truy cập:
- WordPress: http://localhost:6060
- Frontend: http://localhost:3000

## Bước 5: Quản lý dữ liệu

### 5.1. Export dữ liệu

```bash
./scripts/export-data.sh backup-$(date +%Y%m%d).tar.gz
```

Backup bao gồm:
- Database (đã sanitized, loại bỏ API keys/passwords)
- wp-content/uploads

### 5.2. Import dữ liệu

```bash
./scripts/import-data.sh backup-20260119.tar.gz
```

**Lưu ý**: 
- Admin password sẽ được reset về `admin123`
- Cần generate lại WooCommerce API keys
- Cập nhật .env với credentials mới

## Bước 6: Cấu hình WooCommerce

### 6.1. Tạo API Keys

1. Login WordPress admin: http://localhost:6060/wp-admin
2. WooCommerce → Settings → Advanced → REST API
3. Add Key:
   - Description: "Frontend API"
   - User: admin
   - Permissions: Read/Write
4. Copy Consumer Key và Consumer Secret

### 6.2. Cập nhật .env

```bash
nano frontend/.env.production
```

Thêm:
```
WC_CONSUMER_KEY=ck_xxxxx
WC_CONSUMER_SECRET=cs_xxxxx
```

### 6.3. Restart frontend

```bash
docker-compose restart frontend
```

## Troubleshooting

### Lỗi 401 WooCommerce API

**Nguyên nhân**: API keys không đúng hoặc permissions thiếu

**Giải pháp**:
1. Kiểm tra API keys trong .env
2. Verify user có quyền administrator
3. Check mu-plugins/wc-fix-caps.php đã được copy vào container

### Lỗi Module not found

**Nguyên nhân**: tsconfig.json thiếu baseUrl

**Giải pháp**: Đã fix trong code, rebuild image

### Database connection failed

**Nguyên nhân**: Database chưa ready

**Giải pháp**: Đợi health check pass (10-30s)

```bash
docker-compose logs db
```

## Bảo mật

### Checklist bảo mật

- [ ] Đổi admin password mặc định
- [ ] Sử dụng strong passwords trong .env
- [ ] Không commit .env vào git
- [ ] Sử dụng HTTPS trong production
- [ ] Giới hạn IP access nếu cần
- [ ] Backup định kỳ
- [ ] Update WordPress/plugins thường xuyên

### Files không được commit

```
.env
.env.local
.env.production
*.tar.gz
database.sql
wp-content/uploads/
```

## Maintenance

### Update version mới

```bash
# Build version mới
./scripts/build.sh 1.1.0

# Push lên Docker Hub
./scripts/push-dockerhub.sh 1.1.0

# Deploy
./scripts/deploy.sh 1.1.0
```

### Backup định kỳ

Crontab example:

```bash
0 2 * * * cd /path/to/wordpress && ./scripts/export-data.sh /backups/wp-$(date +\%Y\%m\%d).tar.gz
```

### Xem logs

```bash
# Tất cả services
docker-compose logs -f

# Specific service
docker-compose logs -f wordpress
docker-compose logs -f frontend
```

## Support

Nếu gặp vấn đề:
1. Check logs: `docker-compose logs`
2. Verify .env configuration
3. Check health status: `docker-compose ps`
4. Review DEPLOYMENT.md
