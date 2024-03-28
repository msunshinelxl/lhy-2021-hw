#base env
block_device=/dev/vdb
base_dir=/data00/deploy

#tos relative
tos_url=http://test-zq.tos-vpc.hpchub.cloudendpoint.cn
tos_end=http://tos-vpc.hpchub.cloudendpoint.cn
tos_ak=AKLTYjUwYWIwYmY3ZGExNDQwNTkwZDMzNDI5ZDE5M2JjNDk
tos_sk=TlRka05HSXlPVFUyTlROaU5HWTFOVGd6TVRRMk5UQTVaVGxrWVRaaE1EVQ==
tos_re=re
tos_prefix=tos://test-zq
tos_task_max_try=5
log_path=./deploy.log

#cuda install relative
cuda_name=cuda_11.3.1_465.19.01_linux.run
image_name=lab.pytorch.tar
image_repo=hub.byted.org/base/lab.pytorch:1.11.0.post7
container_name=pytorch


#step 0 mkfs current block device is /dev/vdb
mkfs.ext4 $block_device
mkdir -p $base_dir
mount $block_device $base_dir
mkdir -p $base_dir/cuda
mkdir -p $base_dir/docker
mkdir -p $base_dir/images

#step 1 set host info && set tos env && download files

run_command() {
    local cmd=$1
    local retries=$tos_task_max_try
    local count=0

    while [ $count -lt $retries ]; do
        echo "尝试执行 $cmd，第 $((count + 1)) 次..."

        # 执行命令并捕获输出
        output=$($cmd >> $log_path 2>&1)
        status=$?

        # 检查命令是否成功执行
        if [ $status -eq 0 ]; then
            echo "命令 $cmd 执行成功。"
            return 0
        else
            count=$((count + 1))
            echo "命令 $cmd 执行失败。"
            echo "输出: $output，准备重试..."
            sleep 1  # 等待一秒钟再重试
        fi
    done

    echo "命令 $cmd 在 $retries 次重试后仍然失败。"
    return 1
}

run_command "wget $tos_url/deploy/tosutil"
chmod +x ./tosutil
./tosutil config -i $tos_ak -k $tos_sk -e $tos_end -re $tos_re

commands=("./tosutil cp -r $tos_prefix/deploy/cuda/ $base_dir/" "./tosutil cp -r $tos_prefix/deploy/docker/ $base_dir/" "./tosutil cp -r $tos_prefix/deploy/images/ $base_dir/" "./tosutil cp -r $tos_prefix/deploy/test.py $base_dir/")

# 遍历数组并执行命令
for cmd in "${commands[@]}"; do
    run_command "$cmd"
    if [ $? -ne 0 ]; then
        echo "命令 $cmd 执行失败，停止执行后续命令。"
        break
    fi
done

#step 2 install nvidia
sh $base_dir/cuda/$cuda_name

#step 3 install docker
# 3.0 install docker binary
cd $base_dir/docker/
tar -xzf ./docker-20.10.9.tgz
ls ./docker/
cp ./docker/* /usr/bin/
docker -v
echo "list docker.service"
cat /etc/systemd/system/docker.service
cp $base_dir/docker/docker.service /etc/systemd/system/docker.service
chmod +x /etc/systemd/system/docker.service
systemctl start docker
docker images

# 3.1 install docker relative
sudo dpkg -i $base_dir/docker/containerd.io_1.6.28-2_amd64.deb
sudo dpkg -i $base_dir/docker/docker-ce-cli_26.0.0-1~ubuntu.20.04~focal_amd64.deb
sudo dpkg -i $base_dir/docker/docker-ce_26.0.0-1~ubuntu.20.04~focal_amd64.deb
sudo dpkg -i $base_dir/docker/docker-buildx-plugin_0.13.1-1~ubuntu.20.04~focal_amd64.deb
sudo dpkg -i $base_dir/docker/docker-compose-plugin_2.25.0-1~ubuntu.20.04~focal_amd64.deb

#install docker-nvidia relative
sudo dpkg -i $base_dir/docker/libnvidia-container1_1.2.0-1_amd64.deb
sudo dpkg -i $base_dir/docker/libnvidia-container-tools_1.2.0-1_amd64.deb
sudo dpkg -i $base_dir/docker/nvidia-container-toolkit_1.2.1-1_amd64.deb
sudo dpkg -i $base_dir/docker/nvidia-container-runtime_3.3.0-1_amd64.deb
sudo dpkg -i $base_dir/docker/nvidia-docker2_2.4.0-1_all.deb

systemctl restart docker

#step 4 load inmages
sleep 5
echo "load images"
docker load -i $base_dir/images/$image_name
sleep 5
echo "run images"
docker run --name $container_name -v $base_dir:/data00/ -m 100G -c 48 -e NUM_THREADS=8 -it --gpus all $image_repo bash
sleep 5
echo "enter container"
docker docker exec -it $container_name bash