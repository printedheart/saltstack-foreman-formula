#!jinja|yaml

{% from "foreman/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('foreman:lookup')) %}

include:
  - foreman
  - foreman.proxy._user
{% for si in salt['pillar.get']('foreman:lookup:preoxy:sls_include', []) %}
  - {{ si }}
{% endfor %}

extend: {{ salt['pillar.get']('foreman:lookup:proxy:sls_extend', '{}') }}
{#
{-% for k, v in salt['pillar.get']('opennebula:lookup:sunstone:sls_extend', {}).items() }-}
  {-{ k }-}: {-{ v }-}
{-% endfor }-}
#}

proxy:
  pkg:
    - installed
    - pkgs:
{% for p in datamap.proxy.pkgs %}
      - {{ p }}
{% endfor %}
  service:
    - running
    - name: {{ datamap.proxy.service.name|default('foreman-proxy') }}
    - enable: {{ datamap.proxy.service.enable|default(True) }}
    - watch:
{% for c in datamap.proxy.config.manage|default([]) %}
      - file: {{ datamap.proxy.config[c].path }} #TODO ugly
{% endfor %}
    - require:
      - pkg: proxy
{% for c in datamap.proxy.config.manage|default([]) %}
      - file: {{ datamap.proxy.config[c].path }} #TODO ugly
{% endfor %}

{{ salt['pillar.get']('tftp:lookup:root', '/srv/tftp') }}/pxelinux.cfg:
  file:
    - directory
    - user: {{ datamap.proxy.user.name|default('foreman-proxy') }}
    - mode: 755

{{ salt['pillar.get']('tftp:lookup:root', '/srv/tftp') }}/boot:
  file:
    - directory
    - user: {{ datamap.proxy.user.name|default('foreman-proxy') }}
    - mode: 755

{{ salt['pillar.get']('tftp:lookup:root', '/srv/tftp') }}/pxelinux.0:
  file:
    - copy
    - source: {{ salt['pillar.get']('foreman:lookup:syslinux_root', '/usr/lib/syslinux') }}/pxelinux.0

{{ salt['pillar.get']('tftp:lookup:root', '/srv/tftp') }}/menu.c32:
  file:
    - copy
    - source: {{ salt['pillar.get']('foreman:lookup:syslinux_root', '/usr/lib/syslinux') }}/menu.c32

{{ salt['pillar.get']('tftp:lookup:root', '/srv/tftp') }}/chain.c32:
  file:
    - copy
    - source: {{ salt['pillar.get']('foreman:lookup:syslinux_root', '/usr/lib/syslinux') }}/chain.c32

{{ salt['pillar.get']('tftp:lookup:root', '/srv/tftp') }}/memdisk:
  file:
    - copy
    - source: {{ salt['pillar.get']('foreman:lookup:syslinux_root', '/usr/lib/syslinux') }}/memdisk

{{ datamap.proxy.config.settings_yml.path }}:
  file:
    - serialize
    - dataset:
        {{ datamap.proxy.config.settings|default({}) }}
    - formatter: YAML
    - mode: 644
    - user: {{ datamap.proxy.user.name|default('foreman-proxy') }}
    - group: {{ datamap.proxy.group.name|default('foreman-proxy') }}
