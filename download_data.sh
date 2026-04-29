#!/usr/bin/env bash
# =============================================================================
# CLIFF Data Download Script
# Downloads auxiliary data files required by CLIFF to run.
#
# These small data files are NOT in the repository due to MPI/SMPL licensing.
# One-step download gets all 4 files from the SPIN project's UPenn mirror.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"
TARBALL_URL="https://visiondata.cis.upenn.edu/spin/data.tar.gz"
TEMP_DIR=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# Helpers
# =============================================================================

section() {
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

success() { echo -e "  ${GREEN}✅ $1${NC}"; }
warn()    { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
error()   { echo -e "  ${RED}❌ $1${NC}"; }
info()    { echo -e "  ${BLUE}ℹ️  $1${NC}"; }

cleanup() {
    [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# =============================================================================
# Detect download tool
# =============================================================================

detect_downloader() {
    if command -v wget &>/dev/null; then
        echo "wget"
    elif command -v curl &>/dev/null; then
        echo "curl"
    else
        echo ""
    fi
}

download() {
    local url="$1"
    local dest="$2"
    local desc="$3"

    info "Downloading $desc ..."
    info "  From: $url"

    local tool
    tool=$(detect_downloader)

    if [ "$tool" = "wget" ]; then
        if wget -q --show-progress -O "$dest" "$url"; then
            success "Downloaded: $desc"
            return 0
        fi
    elif [ "$tool" = "curl" ]; then
        if curl -L --progress-bar -o "$dest" "$url"; then
            success "Downloaded: $desc"
            return 0
        fi
    else
        error "Neither 'wget' nor 'curl' found."
        echo ""
        echo "    Install one:"
        echo "    Ubuntu/Debian:  sudo apt install wget"
        echo "    CentOS/RHEL:    sudo yum install wget"
        echo ""
        exit 1
    fi

    error "Download failed: $desc"
    return 1
}

# =============================================================================
# Extract specific files from a tarball
# =============================================================================

extract_files() {
    local tarball="$1"
    shift
    local dest_dir="$1"
    shift

    if command -v python3 &>/dev/null; then
        # Use Python tarfile (most portable)
        python3 -c "
import tarfile, os, sys
files_to_extract = set(sys.argv[1:])
dest = '$dest_dir'
os.makedirs(dest, exist_ok=True)
with tarfile.open('$tarball', 'r:gz') as tar:
    for member in tar.getmembers():
        basename = os.path.basename(member.name)
        if basename in files_to_extract:
            member.name = basename  # flatten
            tar.extract(member, path=dest)
            print(f'  Extracted: {basename}')
" "$@"
    else
        # Fallback to tar
        for f in "$@"; do
            tar -xzf "$tarball" -C "$dest_dir" --transform="s|.*/||" "*/$f" 2>/dev/null || true
        done
    fi
}

# =============================================================================
# Check / fix file permissions
# =============================================================================

fix_perms() {
    for f in "$@"; do
        [ -f "$f" ] && chmod 644 "$f"
    done
}

# =============================================================================
# Main
# =============================================================================

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║      CLIFF - Ubuntu 22.04 RTX 4060  ·  Data Downloader          ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"

mkdir -p "$DATA_DIR"

# ---------------------------------------------------------------------------
# Step 1: Download auxiliary data from SPIN tarball (UPenn mirror)
# Contains: smpl_mean_params.npz, J_regressor_h36m.npy, J_regressor_extra.npy, gmm_08.pkl
# ---------------------------------------------------------------------------

section "Step 1/2: Auxiliary Data Files (4 small files, ~14 MB)"

NEEDED_FILES=(
    "smpl_mean_params.npz"
    "J_regressor_h36m.npy"
    "J_regressor_extra.npy"
    "gmm_08.pkl"
)

ALL_PRESENT=true
for f in "${NEEDED_FILES[@]}"; do
    if [ -f "$DATA_DIR/$f" ]; then
        success "Already exists: $f"
    else
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = true ]; then
    echo ""
    info "All 4 auxiliary files are already present — skipping download."
else
    TEMP_DIR=$(mktemp -d)
    TARBALL="$TEMP_DIR/data.tar.gz"

    if download "$TARBALL_URL" "$TARBALL" "SPIN data.tar.gz (auxiliary data)"; then
        info "Extracting needed files ..."
        extract_files "$TARBALL" "$DATA_DIR" "${NEEDED_FILES[@]}"
        fix_perms "${NEEDED_FILES[@]/#/$DATA_DIR/}"

        # Verify
        echo ""
        for f in "${NEEDED_FILES[@]}"; do
            if [ -f "$DATA_DIR/$f" ]; then
                local size
                size=$(du -h "$DATA_DIR/$f" | cut -f1)
                success "Verified: $f ($size)"
            else
                error "Missing after extraction: $f"
            fi
        done
    else
        # ---- Download failed: explain alternatives ----
        echo ""
        warn "The UPenn mirror is unreachable. Fallback options:"
        echo ""
        echo -e "  ${BOLD}Option A — CLIFF Google Drive (has everything bundled):${NC}"
        echo "  https://drive.google.com/drive/folders/1EmSZwaDULhT9m1VvH7YOpCXwBWgYrgwP"
        echo "  Download the folder, copy these 4 files into data/:"
        echo "    smpl_mean_params.npz, J_regressor_h36m.npy, gmm_08.pkl"
        echo "    J_regressor_extra.npy"
        echo ""
        echo -e "  ${BOLD}Option B — SMPL official website (for J_regressor files):${NC}"
        echo "  1. Register (free) at: https://smpl.is.tue.mpg.de"
        echo "  2. Download 'SMPL for Python' → regressor files are included"
        echo "  3. Copy J_regressor_h36m.npy and J_regressor_extra.npy to data/"
        echo ""
        echo -e "  ${BOLD}Option C — Download individually:${NC}"
        echo "  smpl_mean_params.npz:  https://github.com/nkolot/SPIN/raw/master/data/smpl_mean_params.npz"
        echo "  gmm_08.pkl:            Check CLIFF Google Drive or SMPLify-X"
    fi

    cleanup
    trap - EXIT
fi

# ---------------------------------------------------------------------------
# Step 2: Checkpoint & SMPL model reminder
# ---------------------------------------------------------------------------

section "Step 2/2: Model Checkpoints & SMPL Models (NOT downloaded by this script)"

echo "These large / copyrighted files must be obtained separately:"
echo ""

# ---- Checkpoints ----
CKPT_DIR="$DATA_DIR/ckpt"
mkdir -p "$CKPT_DIR"

check_ckpt() {
    if [ -f "$CKPT_DIR/$1" ]; then
        success "Checkpoint: $1"
    else
        warn "Missing:      $1"
        return 1
    fi
}

CKPT_OK=true
check_ckpt "hr48-PA43.0_MJE69.0_MVE81.2_3dpw.pt" || CKPT_OK=false
check_ckpt "res50-PA45.7_MJE72.0_MVE85.3_3dpw.pt" || CKPT_OK=false

if [ "$CKPT_OK" = false ]; then
    echo ""
    echo -e "  ${BOLD}📦 Download from CLIFF Google Drive:${NC}"
    echo "  https://drive.google.com/drive/folders/1EmSZwaDULhT9m1VvH7YOpCXwBWgYrgwP"
    echo "  → Place .pt files in: $CKPT_DIR/"
    echo ""
fi

# ---- SMPL Models ----
echo ""
SMPL_OK=true
for smpl in "SMPL_NEUTRAL.pkl" "SMPL_FEMALE.pkl" "SMPL_MALE.pkl"; do
    if [ -f "$DATA_DIR/$smpl" ]; then
        success "SMPL model: $smpl"
    else
        warn "Missing:     $smpl"
        SMPL_OK=false
    fi
done

if [ "$SMPL_OK" = false ]; then
    echo ""
    echo -e "  ${BOLD}🦴 Download SMPL models from MPI (free registration required):${NC}"
    echo "  1. Register at: https://smpl.is.tue.mpg.de"
    echo "  2. Go to Downloads → SMPL for Python"
    echo "  3. Accept license → download → extract .pkl files to:"
    echo "     $DATA_DIR/"
    echo ""
    echo -e "  ${YELLOW}⚠️  SMPL models are copyrighted by MPI.${NC}"
    echo "  You must register at smpl.is.tue.mpg.de and accept the license."
    echo ""
fi

# ---- MMDetection / MMTracking checkpoints ----
echo ""
MMDET_DIR="$SCRIPT_DIR/mmdetection/checkpoints"
MMTRACK_DIR="$SCRIPT_DIR/mmtracking/checkpoints"

for dir in "$MMDET_DIR" "$MMTRACK_DIR"; do
    mkdir -p "$dir"
done

if [ -f "$MMDET_DIR/yolox_x_8x8_300e_coco_20211126_140254-1ef88d67.pth" ]; then
    success "MMDetection YOLOX checkpoint"
else
    warn "Missing MMDetection YOLOX checkpoint"
    echo "  Download from: https://github.com/open-mmlab/mmdetection/tree/master/configs/yolox"
    echo "  → Place in: $MMDET_DIR/"
fi

if [ -f "$MMTRACK_DIR/bytetrack_yolox_x_crowdhuman_mot17-private-half_20211218_205500-1985c9f0.pth" ]; then
    success "MMTracking ByteTrack checkpoint"
else
    warn "Missing MMTracking ByteTrack checkpoint"
    echo "  Download from: https://github.com/open-mmlab/mmtracking/tree/master/configs/mot/bytetrack"
    echo "  → Place in: $MMTRACK_DIR/"
fi

# =============================================================================
# Summary
# =============================================================================

section "Summary"

MISSING_COUNT=0
for f in "${NEEDED_FILES[@]}"; do
    [ ! -f "$DATA_DIR/$f" ] && MISSING_COUNT=$((MISSING_COUNT + 1))
done

# Count missing checkpoints and SMPL models
for f in "hr48-PA43.0_MJE69.0_MVE81.2_3dpw.pt" "res50-PA45.7_MJE72.0_MVE85.3_3dpw.pt"; do
    [ ! -f "$CKPT_DIR/$f" ] && MISSING_COUNT=$((MISSING_COUNT + 1))
done
for f in "SMPL_NEUTRAL.pkl" "SMPL_FEMALE.pkl" "SMPL_MALE.pkl"; do
    [ ! -f "$DATA_DIR/$f" ] && MISSING_COUNT=$((MISSING_COUNT + 1))
done

if [ $MISSING_COUNT -eq 0 ]; then
    echo -e "${GREEN}${BOLD}  ✅ All data files are in place!${NC}"
    echo ""
    echo "  You can now run CLIFF:"
    echo ""
    echo -e "  ${BOLD}python demo.py \\${NC}"
    echo "      --ckpt data/ckpt/hr48-PA43.0_MJE69.0_MVE81.2_3dpw.pt \\"
    echo "      --backbone hr48 \\"
    echo "      --input_path your_video.mp4 \\"
    echo "      --input_type video \\"
    echo "      --save_results --make_video --frame_rate 30"
    echo ""
else
    echo -e "${YELLOW}${BOLD}  ⚠️  $MISSING_COUNT item(s) still need your attention.${NC}"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │  📦 CLIFF Google Drive (one-stop for checkpoints + data):   │"
    echo "  │  https://drive.google.com/drive/folders/1EmSZwaDULhT9m1V    │"
    echo "  │                                                             │"
    echo "  │  🦴 SMPL Models (registration required):                    │"
    echo "  │  https://smpl.is.tue.mpg.de                                 │"
    echo "  │                                                             │"
    echo "  │  📖 Full setup guide: README_FIX.md                         │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  After obtaining the files, re-run this script to verify:"
    echo "    bash download_data.sh"
    echo ""
fi

echo ""
