@echo off
echo Creating Voice Stack Docker volumes...
docker volume create voice-stack_postgres_data
docker volume create voice-stack_synapse_data
docker volume create voice-stack_media_store
docker volume create voice-stack_element_data  
docker volume create voice-stack_coturn_data
echo Done! Volumes created.