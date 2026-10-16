SASS = node_modules/.bin/sass

target = ../../MacDown/Resources/Styles/GitHub-2020.css

all: $(target)

$(target): index.sass
	@mkdir -p "$(dir $@)"
	@if [ -x "$(SASS)" ]; then \
	  $(SASS) --load-path=node_modules --no-source-map $< | sed s/.markdown-body/body/ > $@; \
	else \
	  echo "warning: sass is not installed; skipping GitHub-2020.css (run npm install in Tools/GitHub-style-generator)"; \
	  touch $@; \
	fi

clean:
	$(RM) $(target)

.PHONY: all clean
