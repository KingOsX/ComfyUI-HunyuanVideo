# ComfyUI + HunyuanVideo 1.5 | RunPod Installer

Installation automatique de **ComfyUI** avec le modele **HunyuanVideo 1.5** (Tencent) sur **RunPod** en une seule commande.

HunyuanVideo 1.5 est un modele text-to-video de 8.3 milliards de parametres, 2x plus rapide que la v1, avec support Super-Resolution (480p->720p->1080p) et generation en 4 steps via LoRA.

## Installation rapide

### Methode 1 : Clone + Run

```bash
git clone https://github.com/VOTRE_USER/ComfyUI-HunyuanVideo.git && bash ComfyUI-HunyuanVideo/install.sh
```

### Methode 2 : Directe (sans clone)

```bash
wget -qO- https://raw.githubusercontent.com/VOTRE_USER/ComfyUI-HunyuanVideo/main/install.sh | bash
```

### Methode 3 : Copier-coller dans le terminal RunPod

```bash
cd /workspace && apt-get update -qq && apt-get install -y -qq git wget ffmpeg libgl1 > /dev/null 2>&1 && git clone https://github.com/comfyanonymous/ComfyUI.git && cd ComfyUI && pip install -q -r requirements.txt && cd custom_nodes && git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && pip install -q -r ComfyUI-VideoHelperSuite/requirements.txt && git clone https://github.com/ltdrdata/ComfyUI-Manager.git && cd /workspace/ComfyUI && mkdir -p models/{diffusion_models,text_encoders,vae,clip_vision,loras} && wget -q --show-progress -O models/diffusion_models/hunyuanvideo1.5_480p_t2v_cfg_distilled_fp8_scaled.safetensors https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/diffusion_models/hunyuanvideo1.5_480p_t2v_cfg_distilled_fp8_scaled.safetensors && wget -q --show-progress -O models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors && wget -q --show-progress -O models/text_encoders/byt5_small_glyphxl_fp16.safetensors https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/text_encoders/byt5_small_glyphxl_fp16.safetensors && wget -q --show-progress -O models/vae/hunyuanvideo15_vae_fp16.safetensors https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/vae/hunyuanvideo15_vae_fp16.safetensors && pip install -q --force-reinstall protobuf sentencepiece && python main.py --listen 0.0.0.0 --port 8188
```

## Options du script

| Flag | Description |
|------|-------------|
| *(defaut)* | T2V 480p cfg distilled **fp8** (~20 GB de modeles) |
| `--720p` | T2V 720p **fp16** (~29 GB) - meilleure qualite, plus de VRAM |
| `--fp16` | Precision **fp16** au lieu de fp8 (~36 GB) |
| `--full` | Tout : 720p T2V + I2V + SR + fp16 + LoRA (~87 GB) |
| `--i2v` | Ajoute le modele **Image-to-Video** + SigCLIP vision |
| `--sr` | Ajoute les modeles **Super-Resolution** (720p + 1080p) |
| `--4step` | Ajoute le **LoRA 4-step** LightX2V (generation ultra-rapide) |
| `--light` | Installation minimale (pas de KJNodes) |

Les flags sont combinables :

```bash
# Installation par defaut (T2V 480p fp8, ~20 GB)
bash install.sh

# T2V 720p avec Image-to-Video
bash install.sh --720p --i2v

# T2V 480p fp8 + Super-Resolution (genere en 480p, upscale en 1080p)
bash install.sh --sr

# T2V 480p fp8 + generation rapide en 4 steps
bash install.sh --4step

# Installation complete qualite maximale (necessite ~100 GB)
bash install.sh --full
```

## Ce qui est installe

### Logiciels

| Composant | Source |
|-----------|--------|
| ComfyUI | [comfyanonymous/ComfyUI](https://github.com/comfyanonymous/ComfyUI) |
| ComfyUI-VideoHelperSuite | [Kosinkadink/ComfyUI-VideoHelperSuite](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite) |
| ComfyUI-Manager | [ltdrdata/ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager) |
| ComfyUI-KJNodes | [kijai/ComfyUI-KJNodes](https://github.com/kijai/ComfyUI-KJNodes) |

> HunyuanVideo 1.5 est supporte **nativement** par ComfyUI (pas besoin de custom node specifique).

### Modeles (config par defaut - fp8 480p)

| Modele | Taille | Emplacement |
|--------|--------|-------------|
| `hunyuanvideo1.5_480p_t2v_cfg_distilled_fp8_scaled.safetensors` | 8.3 GB | `models/diffusion_models/` |
| `qwen_2.5_vl_7b_fp8_scaled.safetensors` | 9.4 GB | `models/text_encoders/` |
| `byt5_small_glyphxl_fp16.safetensors` | 439 MB | `models/text_encoders/` |
| `hunyuanvideo15_vae_fp16.safetensors` | 2.4 GB | `models/vae/` |

**Espace modeles (defaut) : ~20.5 GB**

### Modeles optionnels

| Modele | Flag | Taille |
|--------|------|--------|
| I2V cfg distilled (480p ou 720p) | `--i2v` | 8.3 GB (fp8) / 16.7 GB (fp16) |
| SigCLIP Vision | `--i2v` | 816 MB |
| SR 720p distilled | `--sr` | 8.3 GB (fp8) / 16.7 GB (fp16) |
| SR 1080p distilled | `--sr` | 8.3 GB (fp8) / 16.7 GB (fp16) |
| LightX2V 4-step LoRA | `--4step` | 325 MB |

## Structure des fichiers

```
/workspace/ComfyUI/
  |- main.py
  |- models/
  |   |- diffusion_models/     # Modeles T2V / I2V / SR
  |   |- text_encoders/        # Qwen 2.5 VL 7B + ByT5
  |   |- vae/                  # HunyuanVideo 1.5 VAE
  |   |- clip_vision/          # SigCLIP (pour I2V)
  |   |- loras/                # LoRAs optionnels
  |- custom_nodes/
  |   |- ComfyUI-VideoHelperSuite/
  |   |- ComfyUI-Manager/
  |   |- ComfyUI-KJNodes/
  |- input/
  |- output/                   # Videos generees ici
```

## Nodes ComfyUI utilises

HunyuanVideo 1.5 utilise les nodes **natifs** de ComfyUI :

| Node | Role |
|------|------|
| `UNETLoader` | Charge le modele de diffusion |
| `DualCLIPLoader` | Charge Qwen 2.5 VL 7B + ByT5 |
| `VAELoader` | Charge le VAE |
| `CLIPVisionLoader` | Charge SigCLIP (pour I2V) |
| `EmptyHunyuanLatentVideo` | Cree le latent video initial |
| `KSampler` / `SamplerCustomAdvanced` | Echantillonnage |
| `VAEDecode` | Decode les latents en frames |

## GPU recommande sur RunPod

| GPU | VRAM | Config recommandee | Performance |
|-----|------|--------------------|-------------|
| **A100 80GB** | 80 GB | `--full` (fp16, tout) | Optimale |
| **A100 40GB** | 40 GB | `--720p` ou defaut + `--sr` | Tres bonne |
| **A6000** | 48 GB | `--720p` + `--i2v` | Tres bonne |
| **RTX 4090** | 24 GB | defaut (480p fp8) | Bonne (~75s/clip) |
| **RTX 3090** | 24 GB | defaut (480p fp8) | Correcte |

### Resolutions recommandees selon la VRAM

| VRAM | Resolution | Methode |
|------|------------|---------|
| 80 GB | 1080p | Direct 720p + SR 1080p |
| 40-48 GB | 720p | Direct 720p ou 480p + SR 720p |
| 24 GB | 480p | Direct 480p (+ SR 720p optionnel) |

## Utilisation

Apres l'installation, ComfyUI demarre automatiquement sur le port **8188**.

1. Ouvrez l'URL affichee dans le terminal RunPod (ou via le proxy HTTP RunPod)
2. Construisez votre workflow avec les nodes natifs (voir section "Nodes ComfyUI utilises")
3. Ou chargez un workflow depuis [ComfyUI Examples - HunyuanVideo](https://comfyanonymous.github.io/ComfyUI_examples/hunyuan_video/)
4. Cliquez sur **Queue Prompt** pour generer

### Workflow T2V basique

```
[DualCLIPLoader] -> [CLIPTextEncode] -> [BasicGuider]
[UNETLoader] -> [BasicGuider]
[EmptyHunyuanLatentVideo] -> [SamplerCustomAdvanced] -> [VAEDecode] -> [VHS_VideoCombine]
[VAELoader] -> [VAEDecode]
```

## Relancer ComfyUI

Si ComfyUI s'arrete, relancez-le avec :

```bash
cd /workspace/ComfyUI && python main.py --listen 0.0.0.0 --port 8188
```

Pour les GPUs avec peu de VRAM, ajoutez `--reserve-vram 5` :

```bash
cd /workspace/ComfyUI && python main.py --listen 0.0.0.0 --port 8188 --reserve-vram 5
```

## Depannage

| Probleme | Solution |
|----------|----------|
| Out of memory (OOM) | Utiliser la config par defaut (480p fp8), reduire les frames |
| Modele pas detecte | Verifier que les fichiers sont dans le bon sous-dossier de `models/` |
| Port deja utilise | Changer le port : `python main.py --listen 0.0.0.0 --port 8189` |
| Download interrompu | Relancer `bash install.sh` (reprend les fichiers deja telecharges) |
| `DualCLIPLoader` erreur | Verifier que les 2 text encoders sont bien telecharges |
| Erreur VAE | Verifier que `hunyuanvideo15_vae_fp16.safetensors` est dans `models/vae/` |

## Differences avec HunyuanVideo v1

| | HunyuanVideo v1 | HunyuanVideo 1.5 |
|---|---|---|
| Parametres | 13B | **8.3B** |
| Vitesse | 1x | **2x plus rapide** |
| Text encoder | LLaVA-LLaMA3 + CLIP-L | **Qwen 2.5 VL 7B + ByT5** |
| Super-Resolution | Non | **Oui (480p->720p->1080p)** |
| Step distillation | Non | **Oui (4-step LoRA)** |
| CFG distillation | Non | **Oui (CFG=1, plus rapide)** |

## Licence

Ce script d'installation est fourni tel quel. Les modeles HunyuanVideo sont soumis a la [Tencent Hunyuan Community License](https://huggingface.co/tencent/HunyuanVideo/blob/main/LICENSE). Qwen 2.5 VL est soumis a la licence d'Alibaba.
