.PHONY: allowlists-sync allowlists-check
allowlists-sync:
	python3 tools/allowlists_sync.py --write

allowlists-check:
	python3 tools/allowlists_sync.py --check
