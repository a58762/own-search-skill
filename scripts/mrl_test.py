#!/usr/bin/env python3
"""MRL（Matryoshka）截断测试：EmbeddingGemma 原生支持 128/256/512/768 维，
截断后重新归一化即可用。验证「省存储」的代价到底有多大。
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bench_one import load_docs, pick_sentence, recall  # noqa: E402

N_DOC = int(os.environ.get("N_DOC", "150"))
N_QUERY = int(os.environ.get("N_QUERY", "30"))
DOCLEN = int(os.environ.get("DOCLEN", "1200"))
QP = "task: search result | query: "
DP = "title: none | text: "


def main():
    from local_search import _model
    m = _model()
    rows = load_docs(N_DOC)
    pos = {r[0]: i for i, r in enumerate(rows)}
    rng = np.random.RandomState(42)
    idx = rng.choice(len(rows), size=min(N_QUERY, len(rows)), replace=False)
    docs = [rows[i] for i in idx]
    gold = [pos[d[0]] for d in docs]
    queries = [pick_sentence(d[2], d[1]) for d in docs]
    texts = [DP + (r[2] or "")[:DOCLEN] for r in rows]

    V = np.array(list(m.embed(texts)))
    Vq = np.array(list(m.embed([QP + q for q in queries])))
    full = V.shape[1]
    print(f"全维 {full}，语料 {len(rows)} 条 / query {len(queries)} 条\n")
    print(f"{'维度':>6} {'R@1':>7} {'R@5':>7} {'相对全维':>10} {'存储':>8}")
    print("-" * 44)
    base = None
    for dim in (768, 512, 256, 128, 64):
        if dim > full:
            continue
        A, Aq = V[:, :dim].copy(), Vq[:, :dim].copy()
        A /= np.linalg.norm(A, axis=1, keepdims=True) + 1e-12
        Aq /= np.linalg.norm(Aq, axis=1, keepdims=True) + 1e-12
        r1, r5 = recall(A, Aq, gold, 1), recall(A, Aq, gold, 5)
        if base is None:
            base = r1
        delta = f"{(r1-base)*100:+.1f}pt" if base else "—"
        print(f"{dim:>6} {r1:>7.3f} {r5:>7.3f} {delta:>10} {dim/full*100:>6.0f}%")


if __name__ == "__main__":
    main()
