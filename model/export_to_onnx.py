import argparse, torch, os, json
from TTS.tts.configs.vits_config import VitsConfig
from TTS.tts.models.vits import Vits


def parse_args():
    p = argparse.ArgumentParser(description="Export VITS checkpoint to ONNX")
    p.add_argument("--checkpoint", required=True, help="Path to model .pth")
    p.add_argument("--config", required=True, help="Path to config.json")
    p.add_argument("--speaker_encoder", help="Path to speaker_encoder.pth if any")
    p.add_argument("--output", default="model.onnx", help="Output ONNX file path")
    return p.parse_args()


def main():
    args = parse_args()
    cfg = VitsConfig.parse_file(args.config)
    model = Vits(cfg)
    model.load_checkpoint(args.checkpoint, eval=True)

    if args.speaker_encoder and os.path.exists(args.speaker_encoder):
        model.load_speaker_encoder_checkpoint(args.speaker_encoder)

    model.eval()

    # Dummy inputs: text ids + speaker embedding (optional)
    import numpy as np
    text = torch.LongTensor([[1, 2, 3, 4, 5]])  # dummy indices
    text_lengths = torch.LongTensor([text.shape[-1]])
    sid = torch.LongTensor([0])
    speaker_embedding = torch.zeros(256).unsqueeze(0)

    inputs = (text, text_lengths, sid, speaker_embedding)

    torch.onnx.export(
        model,
        inputs,
        args.output,
        input_names=["text", "text_lengths", "sid", "spk_embed"],
        output_names=["wav"],
        opset_version=13,
        dynamic_axes={"text": {1: "seq"}}
    )
    print(f"ONNX model exported => {args.output}")


if __name__ == "__main__":
    main()